import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';
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

  @override
  void initState() {
    super.initState();
    // Load course progress summary to check certificate eligibility
    context.read<UserProgressBloc>().add(GetCourseProgressSummary(courseId: widget.courseId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserProgressBloc, UserProgressState>(
      listener: (context, state) {
        if (state is CertificateDownloaded) {
          setState(() {
            _isDownloading = false;
          });
          _showDownloadSuccessDialog(state.downloadUrl);
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
      child: BlocBuilder<UserProgressBloc, UserProgressState>(
        builder: (context, state) {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Certificate Ready',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
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
                isEligible ? Icons.download : Icons.lock,
                size: 20,
              ),
        label: Text(
          _isDownloading
              ? 'Downloading...'
              : isEligible
                  ? 'Download Certificate'
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

    // Mark certificate as downloaded
    context.read<UserProgressBloc>().add(MarkCertificateDownloaded(courseId: widget.courseId));
  }

  void _showDownloadSuccessDialog(String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Certificate Downloaded!',
          style: AppTextStyles.h3.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        content: Text(
          'Your certificate for "${widget.courseTitle}" has been marked as downloaded.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          if (downloadUrl.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open certificate URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening certificate: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Open Certificate',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
