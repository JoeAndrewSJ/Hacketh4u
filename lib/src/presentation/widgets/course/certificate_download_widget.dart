import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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

  const CertificateDownloadWidget({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.isDark,
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
    // First check if user has purchased the course
    _checkCourseAccess();
  }

  void _checkCourseAccess() {
    context.read<CourseAccessBloc>().add(
      CheckCourseAccess(courseId: widget.courseId),
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error downloading certificate: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
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

      // Request storage permissions
      await _requestStoragePermissions();

      // Download the certificate image
      final downloadedPath = await _downloadCertificateImage(certificateUrl, widget.courseTitle);
      
      if (downloadedPath != null) {
        // Mark certificate as downloaded in the database
        context.read<UserProgressBloc>().add(MarkCertificateDownloaded(courseId: widget.courseId));
        
        // Show simple success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate downloaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to download certificate');
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

  Future<String?> _downloadCertificateImage(String imageUrl, String courseTitle) async {
    try {
      print('Downloading certificate from: $imageUrl');
      
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;
      final fileName = 'Certificate_${courseTitle.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Try to save to Downloads folder first
      String? filePath = await _saveToDownloads(imageBytes, fileName);
      
      if (filePath == null) {
        // Fallback to app directory
        filePath = await _saveToAppDirectory(imageBytes, fileName);
      }

      return filePath;
    } catch (e) {
      print('Error in _downloadCertificateImage: $e');
      return null;
    }
  }

  Future<String?> _saveToDownloads(Uint8List imageBytes, String fileName) async {
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
            await file.writeAsBytes(imageBytes);
            print('Certificate saved to: ${file.path}');
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

  Future<String> _saveToAppDirectory(Uint8List imageBytes, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    print('Certificate saved to app directory: ${file.path}');
    return file.path;
  }

}
