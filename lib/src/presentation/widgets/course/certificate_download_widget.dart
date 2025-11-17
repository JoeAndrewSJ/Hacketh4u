import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../data/repositories/user_progress_repository.dart';
import '../../../core/di/service_locator.dart';

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
    // Determine if course has any content
    final hasVideos = summary.totalVideos > 0;
    final hasQuizzes = summary.totalQuizzes > 0;
    final hasContent = hasVideos || hasQuizzes;

    return Column(
      children: [
        // Show message if course has no content
        if (!hasContent) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This course has no videos or quizzes yet.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Video Progress (only show if course has videos)
        if (hasVideos) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Videos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${summary.completedVideos}/${summary.totalVideos}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    summary.completedVideos == summary.totalVideos ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: summary.completedVideos == summary.totalVideos ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
          if (hasQuizzes) const SizedBox(height: 12),
        ],

        // Quiz Progress (only show if course has quizzes)
        if (hasQuizzes) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 16,
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Quizzes',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${summary.passedQuizzes}/${summary.totalQuizzes}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    summary.allQuizzesPassed ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: summary.allQuizzesPassed ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ],

        if (hasContent) const SizedBox(height: 16),

        // Overall Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: summary.isCertificateEligible
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: summary.isCertificateEligible
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                summary.isCertificateEligible ? Icons.verified : Icons.pending,
                color: summary.isCertificateEligible ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.isCertificateEligible
                      ? (summary.isCertificateDownloaded
                          ? 'Certificate Downloaded'
                          : 'Certificate Ready to Download!')
                      : summary.ineligibilityReason ?? 'Complete all requirements',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: summary.isCertificateEligible ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
                  : summary.ineligibilityReason ?? 'Complete all requirements',
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

      // Get certificate number and positions from the repository
      // If user already downloaded before, this will return the same certificate number
      final userProgressRepo = sl<UserProgressRepository>();
      final certificateData = await userProgressRepo.getCertificateNumberAndPositions(courseId: widget.courseId);

      final certificateNumber = certificateData['certificateNumber'] as int;
      final nameX = (certificateData['namePositionX'] as num?)?.toDouble();
      final nameY = (certificateData['namePositionY'] as num?)?.toDouble();
      final dateX = (certificateData['issueDatePositionX'] as num?)?.toDouble();
      final dateY = (certificateData['issueDatePositionY'] as num?)?.toDouble();
      final numberX = (certificateData['certificateNumberPositionX'] as num?)?.toDouble();
      final numberY = (certificateData['certificateNumberPositionY'] as num?)?.toDouble();

      // Request storage permissions
      await _requestStoragePermissions();

      // Get issue date from repository (will be same date if already downloaded before)
      final issueDateISO = certificateData['issueDate'] as String;
      final issueDateParsed = DateTime.parse(issueDateISO);
      final issueDate = DateFormat('MMMM dd, yyyy').format(issueDateParsed);

      // Generate PDF certificate with dynamic positions
      final downloadedPath = await _generateCertificatePDF(
        certificateUrl,
        widget.courseTitle,
        userName,
        userEmail,
        summary.averageCompletionPercentage,
        certificateNumber,
        issueDate,
        nameX,
        nameY,
        dateX,
        dateY,
        numberX,
        numberY,
      );

      if (downloadedPath != null) {
        // Mark certificate as downloaded in the database with certificate number and issue date
        context.read<UserProgressBloc>().add(MarkCertificateDownloaded(
          courseId: widget.courseId,
          certificateNumber: certificateNumber,
          issueDate: issueDateISO,
        ));
        
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
    int certificateNumber,
    String issueDate,
    double? nameX,
    double? nameY,
    double? dateX,
    double? dateY,
    double? numberX,
    double? numberY,
  ) async {
    try {
      print('Generating PDF certificate with user name: $userName, H4U25CEH$certificateNumber');
      print('Positions - Name: ($nameX, $nameY), Date: ($dateX, $dateY), Number: ($numberX, $numberY)');

      // Download the certificate image
      final response = await http.get(Uri.parse(certificateUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download certificate image: ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;

      // Decode image to get actual dimensions using dart:ui
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frameInfo = await codec.getNextFrame();
      final actualImageWidth = frameInfo.image.width.toDouble();
      final actualImageHeight = frameInfo.image.height.toDouble();

      print('===== CERTIFICATE PDF GENERATION =====');
      print('Actual image size: ${actualImageWidth}px x ${actualImageHeight}px');
      print('Positions from DB - Name: ($nameX, $nameY), Date: ($dateX, $dateY), Number: ($numberX, $numberY)');

      // IMPORTANT: Positions saved are based on displayed image size in UI, not actual pixels
      // We need to scale coordinates to match the actual image for PDF

      // Standard A4 landscape in points
      const pdfHeight = 595.28;
      final aspectRatio = actualImageWidth / actualImageHeight;
      final pdfWidth = pdfHeight * aspectRatio;

      print('PDF page size: ${pdfWidth.toStringAsFixed(2)}pt x ${pdfHeight}pt');

      // Calculate scale factor from actual image pixels to PDF points
      final scaleX = pdfWidth / actualImageWidth;
      final scaleY = pdfHeight / actualImageHeight;

      print('Scale factors - X: ${scaleX.toStringAsFixed(4)}, Y: ${scaleY.toStringAsFixed(4)}');

      // Scale the positions to PDF coordinates
      final pdfNameX = nameX != null ? nameX * scaleX : null;
      final pdfNameY = nameY != null ? nameY * scaleY : null;
      final pdfDateX = dateX != null ? dateX * scaleX : null;
      final pdfDateY = dateY != null ? dateY * scaleY : null;
      final pdfNumberX = numberX != null ? numberX * scaleX : null;
      final pdfNumberY = numberY != null ? numberY * scaleY : null;

      print('Scaled PDF positions - Name: (${pdfNameX?.toStringAsFixed(2)}, ${pdfNameY?.toStringAsFixed(2)}), Date: (${pdfDateX?.toStringAsFixed(2)}, ${pdfDateY?.toStringAsFixed(2)}), Number: (${pdfNumberX?.toStringAsFixed(2)}, ${pdfNumberY?.toStringAsFixed(2)})');

      // Create PDF document
      final pdf = pw.Document();

      // Create page format
      final pageFormat = PdfPageFormat(
        pdfWidth,
        pdfHeight,
        marginAll: 0,
      );

      // Add page to PDF - Use exact image size for 1:1 coordinate mapping
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Certificate image as background - exact fit
                pw.Positioned.fill(
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.fill, // Fill exactly, no scaling
                  ),
                ),

                // User name overlay - positioned with scaled coordinates
                if (pdfNameX != null && pdfNameY != null)
                  pw.Positioned(
                    left: pdfNameX,
                    top: pdfNameY,
                    child: pw.Text(
                      userName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),

                // Issue date overlay - positioned with scaled coordinates
                if (pdfDateX != null && pdfDateY != null)
                  pw.Positioned(
                    left: pdfDateX,
                    top: pdfDateY,
                    child: pw.Text(
                      issueDate,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),

                // Certificate number overlay - positioned with scaled coordinates
                if (pdfNumberX != null && pdfNumberY != null)
                  pw.Positioned(
                    left: pdfNumberX,
                    top: pdfNumberY,
                    child: pw.Text(
                      ' H4U25CEH$certificateNumber',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Save PDF to device
      final fileName = 'Certificate_${courseTitle.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_$certificateNumber.pdf';
      final filePath = await _savePDFToDevice(pdfBytes, fileName);

      print('PDF certificate generated successfully at: $filePath');
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
