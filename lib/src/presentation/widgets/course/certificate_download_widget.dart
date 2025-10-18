import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../../data/models/user_progress_model.dart';

class CertificateDownloadWidget extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final bool isDark;
  final bool autoCheckProgress;

  const CertificateDownloadWidget({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.isDark,
    this.autoCheckProgress = false, // Don't auto-check progress by default
  });

  @override
  State<CertificateDownloadWidget> createState() => _CertificateDownloadWidgetState();
}

class _CertificateDownloadWidgetState extends State<CertificateDownloadWidget> {
  bool _isDownloading = false;
  bool _hasCourseAccess = false;
  bool _isCheckingAccess = true;

  @override
  void initState() {
    super.initState();
    // Only check course access if auto-checking is enabled
    if (widget.autoCheckProgress) {
      _checkCourseAccess();
    } else {
      // Don't check anything automatically, just show as hidden
      _hasCourseAccess = false;
      _isCheckingAccess = false;
    }
  }

  void _checkCourseAccess() {
    setState(() {
      _isCheckingAccess = true;
    });
    context.read<CourseAccessBloc>().add(
      CheckCourseAccess(courseId: widget.courseId),
    );
  }

  // Public method to manually trigger progress check
  void checkProgress() {
    if (!_hasCourseAccess && !_isCheckingAccess) {
      _checkCourseAccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CourseAccessBloc, CourseAccessState>(
          listener: (context, state) {
            if (state is CourseAccessChecked) {
              setState(() {
                _hasCourseAccess = state.hasAccess;
                _isCheckingAccess = false;
              });
              
              // Only load progress if user has purchased the course
              if (state.hasAccess) {
                context.read<UserProgressBloc>().add(
                  GetCourseProgressSummary(courseId: widget.courseId),
                );
              }
            } else if (state is CourseAccessError) {
              setState(() {
                _isCheckingAccess = false;
              });
            }
          },
        ),
        BlocListener<UserProgressBloc, UserProgressState>(
          listener: (context, state) {
            if (state is CertificateDownloaded) {
              setState(() {
                _isDownloading = false;
              });
              // Success feedback is already handled in the download method
            } else if (state is UserProgressError) {
              setState(() {
                _isDownloading = false;
              });
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Error downloading certificate: ${state.error}'),
              //     backgroundColor: Colors.red,
              //   ),
              // );
            }
          },
        ),
      ],
      child: BlocBuilder<UserProgressBloc, UserProgressState>(
        builder: (context, state) {
          // Show loading while checking course access
          if (_isCheckingAccess) {
            return _buildLoadingState();
          }
          
          // Show simple certificate button if not auto-checking
          if (!widget.autoCheckProgress && !_hasCourseAccess && !_isCheckingAccess) {
            return _buildSimpleCertificateButton();
          }
          
          // Don't show certificate section if user hasn't purchased the course
          if (!_hasCourseAccess) {
            return const SizedBox.shrink(); // Hide the certificate widget
          }
          
          // Show certificate section only if user has access
          if (state is CourseProgressSummaryLoaded) {
            return _buildCertificateSection(state.summary);
          } else if (state is UserProgressLoading) {
            return _buildLoadingState();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSimpleCertificateButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[700]?.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? Colors.grey[600]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 16,
            color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            'Certificate',
            style: AppTextStyles.bodySmall.copyWith(
              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: checkProgress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Check',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSection(CourseProgressSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Course Certificate',
                style: AppTextStyles.h3.copyWith(
                  color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress information
          _buildProgressInfo(summary),
          const SizedBox(height: 16),
          
          // Certificate download button
          _buildCertificateButton(summary),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(CourseProgressSummary summary) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Completion',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              '${summary.completedVideos}/${summary.totalVideos} videos',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        LinearProgressIndicator(
          value: summary.averageCompletionPercentage / 100,
          backgroundColor: widget.isDark ? Colors.grey[700] : Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            summary.isCertificateEligible ? Colors.green : Colors.orange,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${summary.averageCompletionPercentage.toStringAsFixed(1)}% Complete',
              style: AppTextStyles.bodySmall.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            if (summary.isCertificateEligible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.isCertificateDownloaded 
                      ? Colors.blue.withOpacity(0.1) 
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      summary.isCertificateDownloaded ? Icons.download_done : Icons.check_circle,
                      color: summary.isCertificateDownloaded ? Colors.blue : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      summary.isCertificateDownloaded ? 'Downloaded' : 'Certificate Ready',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: summary.isCertificateDownloaded ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCertificateButton(CourseProgressSummary summary) {
    final isEligible = summary.isCertificateEligible;
    final hasUrl = summary.certificateTemplateUrl != null && summary.certificateTemplateUrl!.isNotEmpty;
    final isDownloaded = summary.isCertificateDownloaded;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isEligible && hasUrl && !_isDownloading) ? _downloadCertificate : null,
        icon: _isDownloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.download,
                size: 20,
              ),
        label: Text(
          _isDownloading
              ? 'Downloading...'
              : isEligible
                  ? (isDownloaded ? 'Download Certificate Again' : 'Download Certificate')
                  : 'Complete ${(100 - summary.averageCompletionPercentage).toStringAsFixed(1)}% more to unlock certificate',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isEligible ? Colors.white : (widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEligible ? Colors.green : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
          foregroundColor: isEligible ? Colors.white : (widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEligible ? 2 : 0,
        ),
      ),
    );
  }

  void _downloadCertificate() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Get the current state to access certificate URL
      final currentState = context.read<UserProgressBloc>().state;
      if (currentState is! CourseProgressSummaryLoaded) {
        throw Exception('Course progress not loaded');
      }

      final summary = currentState.summary;
      final certificateUrl = summary.certificateTemplateUrl;
      
      if (certificateUrl == null || certificateUrl.isEmpty) {
        throw Exception('Certificate URL not available');
      }

      // Get current user information
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.displayName ?? 'User';
      final userEmail = user.email ?? '';

      // Request storage permissions
      await _requestStoragePermissions();

      // Generate PDF certificate with user name overlaid on the certificate image
      final downloadedPath = await _generateCertificatePDF(
        certificateUrl, 
        widget.courseTitle, 
        userName, 
        userEmail,
        summary.averageCompletionPercentage,
      );
      
      if (downloadedPath != null) {
        // Mark certificate as downloaded in the database
        context.read<UserProgressBloc>().add(MarkCertificateDownloaded(courseId: widget.courseId));
        
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: isDarkDialog ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Header with gradient
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Success!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Certificate generated successfully!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkDialog ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.folder_rounded,
                                        color: Colors.green.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Saved Location',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    downloadedPath.split('/').last,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkDialog ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // OK Button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Great!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        throw Exception('Failed to generate certificate');
      }
    } catch (e) {
      print('Error downloading certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _requestStoragePermissions() async {
    // Request storage permissions for Android
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      final manageStorageStatus = await Permission.manageExternalStorage.request();
      
      if (storageStatus != PermissionStatus.granted && 
          manageStorageStatus != PermissionStatus.granted) {
        throw Exception('Storage permission denied');
      }
    }
  }


  Future<String?> _generateCertificatePDF(
    String certificateUrl,
    String courseTitle,
    String userName,
    String userEmail,
    double completionPercentage,
  ) async {
    try {
      print('Generating PDF certificate with user name: $userName');
      
      // Download the certificate image
      final response = await http.get(Uri.parse(certificateUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download certificate image: ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;
      
      // Create PDF document
      final pdf = pw.Document();

      // Add page to PDF - Landscape format
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Container(
              color: PdfColors.white, // White background
              child: pw.Center(
                child: pw.Container(
                  width: 800, // Fixed width for certificate
                  height: 600, // Fixed height for certificate
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(10),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey300,
                        blurRadius: 10,
                        offset: const PdfPoint(0, 5),
                      ),
                    ],
                  ),
                  child: pw.Container(
                    width: 800,
                    height: 600,
                    child: pw.Stack(
                      children: [
                        // Certificate image as background
                        pw.Positioned.fill(
                          child: pw.Image(
                            pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                        
                        // User name overlay - positioned on the image
                        pw.Positioned(
                          left: 50,
                          top: 230,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            child: pw.Text(
                              userName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Save PDF to device
      final fileName = 'Certificate_${courseTitle.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await _savePDFToDevice(pdfBytes, fileName);

      return filePath;
    } catch (e) {
      print('Error generating PDF certificate: $e');
      return null;
    }
  }

  Future<String?> _savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      // Try to save to Downloads folder first
      String? filePath = await _savePDFToDownloads(pdfBytes, fileName);
      
      if (filePath == null) {
        // Fallback to app directory
        filePath = await _savePDFToAppDirectory(pdfBytes, fileName);
      }

      return filePath;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  Future<String?> _savePDFToDownloads(Uint8List pdfBytes, String fileName) async {
    try {
      // Try multiple possible Downloads paths
      final possiblePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final path in possiblePaths) {
        try {
          final downloadsDir = Directory(path);
          if (await downloadsDir.exists()) {
            final file = File('${downloadsDir.path}/$fileName');
            await file.writeAsBytes(pdfBytes);
            print('PDF certificate saved to: ${file.path}');
            return file.path;
          }
        } catch (e) {
          print('Failed to save to $path: $e');
          continue;
        }
      }
      return null;
    } catch (e) {
      print('Error saving to Downloads: $e');
      return null;
    }
  }

  Future<String> _savePDFToAppDirectory(Uint8List pdfBytes, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    print('PDF certificate saved to app directory: ${file.path}');
    return file.path;
  }

}
