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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Thumbnail
                _buildThumbnail(thumbnailUrl),
                const SizedBox(width: 16),
                
                // Course Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress Bar
                      _buildProgressBar(progressPercentage, completedVideos, totalVideos),
                      const SizedBox(height: 8),
                      
                      // Course Stats
                      Row(
                        children: [
                          _buildStatItem(
                            icon: Icons.video_library_outlined,
                            text: '$moduleCount modules',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            icon: Icons.access_time,
                            text: _formatDuration(totalDuration),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Purchase Status and Invoice
                      Row(
                        children: [
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
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Purchased',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (payment != null && user != null) ...[
                            const SizedBox(width: 8),
                            InvoiceDownloadWidget(
                              payment: payment!,
                              course: _createCourseModel(),
                              user: user!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryLight.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
            ? Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultThumbnail();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultThumbnail();
                },
              )
            : _buildDefaultThumbnail(),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.school,
        color: AppTheme.primaryLight,
        size: 32,
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
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

  Widget _buildProgressBar(double progressPercentage, int completedVideos, int totalVideos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress percentage and video count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progressPercentage.toStringAsFixed(0)}% Complete',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
           
          ],
        ),
        const SizedBox(height: 6),
        
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressPercentage / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: progressPercentage >= 100 
                    ? Colors.green 
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(3),
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
