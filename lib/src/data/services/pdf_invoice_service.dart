import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice_model.dart';
import '../models/course_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class PDFInvoiceService {
  static const String _companyName = 'Hackethos4u';
  static const String _companyEmail = 'support@hackethos4u.com';
  static const String _companyPhone = '+1 (555) 123-4567';
  static const String _companyAddress = '123 Tech Street, Innovation City, IC 12345';

  /// Generate and save PDF invoice
  static Future<String> generateInvoice({
    required InvoiceModel invoice,
    required UserModel user,
    required CourseModel course,
    required PaymentModel payment,
  }) async {
    final pdf = await _createInvoicePDF(invoice, user, course, payment);
    final pdfBytes = await pdf.save();
    final fileName = 'Invoice_${invoice.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isAndroid) {
      try {
        // Request storage permission
        var status = await Permission.storage.request();

        // For Android 13+, photos permission is used instead
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }

        if (status.isGranted || status.isLimited) {
          // Try to save to Downloads directory
          final downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);

          // Check if directory exists
          if (await downloadsDir.exists()) {
            final file = File('$downloadsPath/$fileName');
            try {
              await file.writeAsBytes(pdfBytes);
              debugPrint('✅ PDF saved successfully to: ${file.path}');
              return file.path;
            } catch (e) {
              debugPrint('⚠️ Failed to write to Downloads folder: $e');
            }
          } else {
            // Try to create Downloads directory
            try {
              await downloadsDir.create(recursive: true);
              final file = File('$downloadsPath/$fileName');
              await file.writeAsBytes(pdfBytes);
              debugPrint('✅ PDF saved successfully to: ${file.path}');
              return file.path;
            } catch (e) {
              debugPrint('⚠️ Failed to create Downloads folder: $e');
            }
          }
        }

        // If Downloads doesn't work, try external storage directory
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Create a Downloads folder in the app's external directory
            final appDownloadsDir = Directory('${externalDir.path}/Downloads');
            await appDownloadsDir.create(recursive: true);

            final file = File('${appDownloadsDir.path}/$fileName');
            await file.writeAsBytes(pdfBytes);
            debugPrint('✅ PDF saved to app external directory: ${file.path}');
            return file.path;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to save to external storage: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Permission or save error: $e');
      }
    }

    // Final fallback: Save to app documents directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      debugPrint('✅ PDF saved to app documents directory: ${file.path}');
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF invoice: $e');
    }
  }

  /// Create the PDF document
  static Future<pw.Document> _createInvoicePDF(
    InvoiceModel invoice,
    UserModel user,
    CourseModel course,
    PaymentModel payment,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 30),
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 20),
              _buildBillingInfo(user),
              pw.SizedBox(height: 20),
              _buildCourseDetails(course),
              pw.SizedBox(height: 20),
              _buildPaymentDetails(payment),
              pw.SizedBox(height: 20),
              _buildTotals(invoice),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Build header section
  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _companyName,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Online Learning Platform',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: 100,
              height: 100,
              decoration: pw.BoxDecoration(
                color: PdfColors.green800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'H4U',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build invoice information
  static pw.Widget _buildInvoiceInfo(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Invoice #: ${invoice.id}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Date: ${_formatDate(invoice.purchaseDate)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Payment Status',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: invoice.status == 'completed' ? PdfColors.green100 : PdfColors.orange100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  invoice.status.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice.status == 'completed' ? PdfColors.green800 : PdfColors.orange800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build billing information
  static pw.Widget _buildBillingInfo(UserModel user) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                user.name,
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                user.email,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'From:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _companyName,
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                _companyEmail,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                _companyPhone,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build course details
  static pw.Widget _buildCourseDetails(CourseModel course) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Course Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      course.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      course.description,
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Course ID: ${course.id}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Access: Lifetime',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build payment details
  static pw.Widget _buildPaymentDetails(PaymentModel payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment Method:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(payment.paymentMethod, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Transaction ID:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(payment.razorpayPaymentId ?? payment.paymentId, style: pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment Date:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(_formatDate(payment.createdAt), style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Course Price:', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Rs. ${invoice.coursePrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          if (invoice.discountAmount != null && invoice.discountAmount! > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Discount (${invoice.discountCode}):', style: pw.TextStyle(fontSize: 14, color: PdfColors.green600)),
                pw.Text('-Rs. ${invoice.discountAmount!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, color: PdfColors.green600)),
              ],
            ),
          ],
          if (invoice.taxAmount > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tax:', style: pw.TextStyle(fontSize: 14)),
                pw.Text('Rs. ${invoice.taxAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
              ],
            ),
          ],
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Rs. ${invoice.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for choosing Hackethos4u!',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'For support, contact us at $_companyEmail or visit our website',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Text('Email: $_companyEmail', style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
              pw.Text('Phone: $_companyPhone', style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
              pw.Text('Web: www.hackethos4u.com', style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Open the generated PDF file
  static Future<void> openPDF(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('📄 PDF available at: $filePath');

        // Try to open the PDF with default viewer
        try {
          final uri = Uri.file(filePath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('✅ PDF opened in default viewer');
          } else {
            debugPrint('⚠️ Cannot launch PDF, but file saved successfully');
          }
        } catch (e) {
          // Opening failed, but file was saved successfully
          debugPrint('⚠️ Could not auto-open PDF: $e');
          debugPrint('✅ File saved to: $filePath');
        }
      } else {
        debugPrint('❌ PDF file does not exist at: $filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Error with PDF file: $e');
      debugPrint('📄 File location: $filePath');
    }
  }
}
