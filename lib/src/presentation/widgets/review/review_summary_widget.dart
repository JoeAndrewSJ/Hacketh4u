import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/review_model.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final CourseReviewSummary? summary;
  final bool isDark;

  const ReviewSummaryWidget({
    super.key,
    this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating
          _buildOverallRating(),
          const SizedBox(height: 20),
          
          // Rating Distribution
          _buildRatingDistribution(),
          const SizedBox(height: 16),
          
          // Review Stats
          _buildReviewStats(),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Row(
      children: [
        // Large Rating Display
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  summary!.averageRating.toStringAsFixed(1),
                  style: AppTextStyles.h1.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ 5.0',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < summary!.averageRating.floor() 
                      ? Icons.star 
                      : index < summary!.averageRating 
                          ? Icons.star_half 
                          : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          ],
        ),
        const Spacer(),
        
        // Review Count
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary!.totalReviews}',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Reviews',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    // Parse rating distribution (simplified for now)
    final distribution = <int, int>{};
    for (int i = 5; i >= 1; i--) {
      distribution[i] = (summary!.totalReviews / 5).round(); // Simplified distribution
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Distribution',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...distribution.entries.map((entry) {
          final rating = entry.key;
          final count = entry.value;
          final percentage = summary!.totalReviews > 0 
              ? (count / summary!.totalReviews * 100) 
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Star Rating
                Row(
                  children: [
                    Text(
                      '$rating',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // Progress Bar
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(rating),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Count
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReviewStats() {
    return Row(
      children: [
        // Verified Reviews
        Expanded(
          child: _buildStatItem(
            icon: Icons.verified,
            label: 'Verified',
            value: '${summary!.verifiedReviews}',
            color: Colors.blue,
          ),
        ),
        
        // Total Reviews
        Expanded(
          child: _buildStatItem(
            icon: Icons.reviews,
            label: 'Total',
            value: '${summary!.totalReviews}',
            color: AppTheme.primaryLight,
          ),
        ),
        
        // Average Rating
        Expanded(
          child: _buildStatItem(
            icon: Icons.star,
            label: 'Average',
            value: summary!.averageRating.toStringAsFixed(1),
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.reviews_outlined,
              size: 48,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this course!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
