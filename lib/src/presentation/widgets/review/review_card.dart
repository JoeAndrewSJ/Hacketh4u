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
      padding: const EdgeInsets.all(18),
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
          // Review Header
          _buildReviewHeader(),
          const SizedBox(height: 12),

          // Review Comment
          _buildComment(),

          // Admin Response (if exists)
          if (review.adminResponse != null) ...[
            const SizedBox(height: 10),
            _buildAdminResponse(),
          ],

          // Review Footer
          const SizedBox(height: 6),
          _buildReviewFooter(),
        ],
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 14),

        // User Info with inline rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.userName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Inline rating stars
                  ...List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '${review.rating}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(review.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF9E9E9E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Actions Menu - Smaller
        if (isCurrentUser)
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
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
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
            ],
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
      ],
    );
  }

  Widget _buildComment() {
    // Handle empty or null comments
    final commentText = review.comment.isNotEmpty ? review.comment : 'No comment provided';

    return Text(
      commentText,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
        height: 1.6,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAdminResponse() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.2),
          width: 1,
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
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Admin Response',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              if (review.adminResponseAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${_formatDate(review.adminResponseAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryLight.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.adminResponse!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
              fontSize: 13,
              height: 1.5,
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

        // Report Button - Minimal
        Builder(
          builder: (context) => InkWell(
            onTap: () => _showReportDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Report',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[400],
                      fontSize: 11,
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
      builder: (context) {
        final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: isDarkDialog ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDarkDialog ? AppTheme.surfaceDark : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkDialog ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.flag_rounded,
                            size: 24,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Report Review',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDarkDialog ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDarkDialog ? AppTheme.textSecondaryDark : const Color(0xFF9E9E9E),
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
                        'Report this review?',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkDialog ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Our team will review this report and take appropriate action if needed.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color: isDarkDialog ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDarkDialog ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                foregroundColor: isDarkDialog ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.red.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Report',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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
