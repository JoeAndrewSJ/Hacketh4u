import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/pdf_invoice_service.dart';

class InvoiceDownloadWidget extends StatefulWidget {
  final PaymentModel payment;
  final CourseModel course;
  final UserModel user;

  const InvoiceDownloadWidget({
    Key? key,
    required this.payment,
    required this.course,
    required this.user,
  }) : super(key: key);

  @override
  State<InvoiceDownloadWidget> createState() => _InvoiceDownloadWidgetState();

  // Static method for downloading invoice from other screens
  static Future<String> downloadInvoice({
    required PaymentModel payment,
    required CourseModel course,
    required UserModel user,
  }) async {
    try {
      // Create invoice model
      final invoice = InvoiceModel(
        id: 'INV-${payment.id.length > 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}',
        userId: payment.userId,
        userName: user.name,
        userEmail: user.email,
        courseId: course.id,
        courseName: course.title,
        courseDescription: course.description,
        coursePrice: payment.finalAmount,
        paymentId: payment.paymentId,
        paymentMethod: payment.paymentMethod,
        purchaseDate: payment.paymentDate,
        accessEndDate: DateTime.now().add(const Duration(days: 365)),
        status: payment.paymentStatus,
        currency: 'INR',
        taxAmount: 0.0, // No tax for now
        totalAmount: payment.finalAmount,
        discountCode: payment.couponCode,
        discountAmount: payment.discountAmount,
      );

      // Generate and save PDF
      final filePath = await PDFInvoiceService.generateInvoice(
        invoice: invoice,
        user: user,
        course: course,
        payment: payment,
      );

      // Try to open the PDF, but don't fail if it doesn't work
      try {
        await PDFInvoiceService.openPDF(filePath);
      } catch (e) {
        // PDF was generated successfully, but couldn't be opened automatically
        // The file is saved and user can access it manually
        debugPrint('PDF generated successfully at: $filePath');
        // Don't rethrow the exception - the PDF was created successfully
      }

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }
}

class _InvoiceDownloadWidgetState extends State<InvoiceDownloadWidget> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isGenerating ? null : _generateInvoice,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isGenerating
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.receipt_long,
                        color: AppTheme.primaryLight,
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Invoice',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get your purchase receipt in PDF format',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Invoice #${widget.payment.id.length > 8 ? widget.payment.id.substring(0, 8) : widget.payment.id}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateInvoice() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create invoice model from payment data
      final invoice = InvoiceModel(
        id: widget.payment.id,
        userId: widget.user.uid,
        userName: widget.user.name,
        userEmail: widget.user.email,
        courseId: widget.course.id,
        courseName: widget.course.title,
        courseDescription: widget.course.description,
        coursePrice: widget.payment.finalAmount,
        paymentId: widget.payment.paymentId,
        paymentMethod: widget.payment.paymentMethod,
        purchaseDate: widget.payment.createdAt,
        accessEndDate: DateTime.now().add(const Duration(days: 365)),
        status: widget.payment.paymentStatus,
        totalAmount: widget.payment.finalAmount,
        discountCode: widget.payment.couponCode,
        discountAmount: widget.payment.discountAmount,
      );

      // Generate PDF
      final filePath = await PDFInvoiceService.generateInvoice(
        invoice: invoice,
        user: widget.user,
        course: widget.course,
        payment: widget.payment,
      );

      // Open the PDF
      await PDFInvoiceService.openPDF(filePath);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Invoice downloaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error generating invoice: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

/// Invoice download button for quick access
class InvoiceDownloadButton extends StatelessWidget {
  final PaymentModel payment;
  final CourseModel course;
  final UserModel user;
  final bool isCompact;

  const InvoiceDownloadButton({
    Key? key,
    required this.payment,
    required this.course,
    required this.user,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isCompact) {
      return IconButton(
        onPressed: () => _showInvoiceDialog(context),
        icon: Icon(
          Icons.receipt_long,
          color: AppTheme.primaryLight,
        ),
        tooltip: 'Download Invoice',
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showInvoiceDialog(context),
      icon: const Icon(Icons.receipt_long),
      label: const Text('Download Invoice'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Download Invoice',
                style: AppTextStyles.h2.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate and download your purchase invoice for ${course.title}',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateInvoice(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Generate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateInvoice(BuildContext context) async {
    try {
      // Create invoice model from payment data
      final invoice = InvoiceModel(
        id: payment.id,
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        courseId: course.id,
        courseName: course.title,
        courseDescription: course.description,
        coursePrice: payment.finalAmount,
        paymentId: payment.paymentId,
        paymentMethod: payment.paymentMethod,
        purchaseDate: payment.createdAt,
        accessEndDate: DateTime.now().add(const Duration(days: 365)),
        status: payment.paymentStatus,
        totalAmount: payment.finalAmount,
        discountCode: payment.couponCode,
        discountAmount: payment.discountAmount,
      );

      // Generate PDF
      final filePath = await PDFInvoiceService.generateInvoice(
        invoice: invoice,
        user: user,
        course: course,
        payment: payment,
      );

      // Open the PDF
      await PDFInvoiceService.openPDF(filePath);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Invoice downloaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error generating invoice: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
