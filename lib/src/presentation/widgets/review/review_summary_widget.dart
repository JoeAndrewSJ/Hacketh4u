import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/review_model.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final CourseReviewSummary? summary;
  final bool isDark;
  final List<ReviewModel>? reviews; // Add reviews for fallback calculation

  const ReviewSummaryWidget({
    super.key,
    this.summary,
    required this.isDark,
    this.reviews,
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
          color: isDark ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating with Distribution
          _buildOverallRating(),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Large Rating Display
            SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary!.averageRating.toStringAsFixed(1),
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 48,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < summary!.averageRating.floor()
                            ? Icons.star_rounded
                            : index < summary!.averageRating
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary!.totalReviews} Reviews',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Vertical Divider
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
            ),

            // Rating Distribution (compact)
            Expanded(
              child: _buildCompactDistribution(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDistribution() {
    Map<int, int> distribution = summary!.getRatingDistribution();

    if (distribution.isEmpty && reviews != null && reviews!.isNotEmpty) {
      for (var review in reviews!) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }
    }

    if (distribution.isEmpty) {
      for (int i = 5; i >= 1; i--) {
        distribution[i] = 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int rating = 5; rating >= 1; rating--)
          Padding(
            padding: EdgeInsets.only(bottom: rating > 1 ? 6 : 0),
            child: _buildRatingBar(
              rating,
              distribution[rating] ?? 0,
              summary!.totalReviews,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingBar(int rating, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          '$rating',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 3),
        Icon(
          Icons.star_rounded,
          color: Colors.amber,
          size: 11,
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 1,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 15,
          child: Text(
            '$count',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
              fontSize: 10,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    // Parse rating distribution from the summary
    Map<int, int> distribution = summary!.getRatingDistribution();
    
    // If no distribution data, calculate from actual reviews
    if (distribution.isEmpty && reviews != null && reviews!.isNotEmpty) {
      distribution = _calculateRatingDistributionFromReviews(reviews!);
    }
    
    // If still no distribution data, initialize with zeros
    if (distribution.isEmpty) {
      for (int i = 5; i >= 1; i--) {
        distribution[i] = 0;
      }
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

  // Helper method to calculate rating distribution from actual reviews
  Map<int, int> _calculateRatingDistributionFromReviews(List<ReviewModel> reviews) {
    final Map<int, int> distribution = {};
    
    // Initialize all ratings with 0
    for (int i = 1; i <= 5; i++) {
      distribution[i] = 0;
    }
    
    // Count each rating
    for (final review in reviews) {
      if (review.rating >= 1 && review.rating <= 5) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }
    }
    
    print('Calculated rating distribution from reviews: $distribution');
    return distribution;
  }
}
