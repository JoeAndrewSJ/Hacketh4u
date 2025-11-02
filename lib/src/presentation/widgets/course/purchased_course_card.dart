import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../invoice/invoice_download_widget.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/user_model.dart';

class PurchasedCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final VoidCallback onTap;
  final PaymentModel? payment;
  final UserModel? user;

  const PurchasedCourseCard({
    super.key,
    required this.course,
    required this.isDark,
    required this.onTap,
    this.payment,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = course['thumbnailUrl'] as String?;
    final title = course['title'] as String? ?? 'Untitled Course';
    final description = course['description'] as String?;
    final totalDuration = course['totalDuration'] as int? ?? 0;
    final moduleCount = course['moduleCount'] as int? ?? 0;

    // Get progress information - only percentage from progress data
    final progressData = course['progress'] as Map<String, dynamic>?;
    final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;

    // Keep video counts as 0 since we only want percentage from progress data
    final completedVideos = 0;
    final totalVideos = 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Course Thumbnail - Compact circular design
                _buildThumbnail(thumbnailUrl),
                const SizedBox(width: 14),

                // Course Details - Compact layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.1,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar - Compact
                      _buildProgressBar(progressPercentage),
                      const SizedBox(height: 10),

                      // Course Stats - Compact row
                      Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.play_circle_outline,
                            text: '$moduleCount modules',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            icon: Icons.schedule_outlined,
                            text: _formatDuration(totalDuration),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Arrow in circle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? thumbnailUrl) {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
            ? Image.network(
                thumbnailUrl,
                width: 90,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultThumbnail();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.grey.shade600 : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  );
                },
              )
            : _buildDefaultThumbnail(),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
      ),
      child: Icon(
        Icons.school_rounded,
        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B6B6B),
        size: 36,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF6B6B6B),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Widget _buildProgressBar(double progressPercentage) {
    final isComplete = progressPercentage >= 100;
    final progressColor = isComplete
        ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A))
        : AppTheme.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress percentage with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: progressColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.timelapse,
                    size: 12,
                    color: progressColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${progressPercentage.toStringAsFixed(0)}% ${isComplete ? 'Completed' : 'Progress'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(2.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressPercentage / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  CourseModel _createCourseModel() {
    return CourseModel(
      id: course['id'] as String? ?? '',
      title: course['title'] as String? ?? 'Untitled Course',
      description: course['description'] as String? ?? '',
      instructor: course['instructor'] as String? ?? 'Unknown Instructor',
      price: (course['price'] as num?)?.toDouble() ?? 0.0,
      thumbnailUrl: course['thumbnailUrl'] as String?,
      category: course['category'] as String? ?? '',
      level: course['level'] as String? ?? 'beginner',
      duration: course['totalDuration'] as int? ?? 0,
      moduleCount: course['moduleCount'] as int? ?? 0,
      isPublished: true,
      isPremium: true,
      rating: (course['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: course['totalReviews'] as int? ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
