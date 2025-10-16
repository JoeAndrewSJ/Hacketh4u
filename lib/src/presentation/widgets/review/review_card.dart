import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/review_model.dart';
import '../../../core/bloc/review/review_bloc.dart';
import '../../../core/bloc/review/review_event.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isDark;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isDark,
    this.isCurrentUser = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          _buildReviewHeader(),
          const SizedBox(height: 16),
          
          // Rating
          _buildRating(),
          const SizedBox(height: 16),
          
          // Review Comment
          _buildComment(),
          
          // Admin Response (if exists)
          if (review.adminResponse != null) ...[
            const SizedBox(height: 20),
            _buildAdminResponse(),
          ],
          
          // Review Footer
          const SizedBox(height: 20),
          _buildReviewFooter(),
        ],
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      children: [
        // User Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
          backgroundImage: review.userProfileImageUrl != null 
              ? NetworkImage(review.userProfileImageUrl!)
              : null,
          child: review.userProfileImageUrl == null
              ? Icon(
                  Icons.person,
                  color: AppTheme.primaryLight,
                  size: 20,
                )
              : null,
        ),
        const SizedBox(width: 12),
        
        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(review.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        
        // Actions Menu
        if (isCurrentUser)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        // Star Rating
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '${review.rating}.0',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildComment() {
    // Handle empty or null comments
    final commentText = review.comment.isNotEmpty ? review.comment : 'No comment provided';
    
    // Debug: Print comment to see what we're getting
    print('ReviewCard: Displaying comment: "$commentText"');
    print('ReviewCard: Comment length: ${commentText.length}');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Text(
        commentText,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          height: 1.6,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildAdminResponse() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: AppTheme.primaryLight,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Admin Response',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (review.adminResponseAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _formatDate(review.adminResponseAt!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryLight.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.adminResponse!,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFooter() {
    return Row(
      children: [
        const Spacer(),
        
        // Report Button
        Builder(
          builder: (context) => InkWell(
            onTap: () => _showReportDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Report',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: const Text('Are you sure you want to report this review as inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ReviewBloc>().add(ReportReview(reviewId: review.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review reported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
