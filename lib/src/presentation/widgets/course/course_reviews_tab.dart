import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/review/review_bloc.dart';
import '../../../core/bloc/review/review_event.dart';
import '../../../core/bloc/review/review_state.dart';
import '../../../data/models/review_model.dart';
import '../review/review_summary_widget.dart';
import '../review/review_card.dart';
import '../review/review_form.dart';

class CourseReviewsTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final bool hasPurchased;

  const CourseReviewsTab({
    super.key,
    required this.course,
    required this.isDark,
    this.hasPurchased = false,
  });

  @override
  State<CourseReviewsTab> createState() => _CourseReviewsTabState();
}

class _CourseReviewsTabState extends State<CourseReviewsTab> {
  List<ReviewModel> _reviews = [];
  CourseReviewSummary? _summary;
  ReviewModel? _userReview;
  bool _isLoading = true;
  bool _hasMoreReviews = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    context.read<ReviewBloc>().add(LoadCourseReviews(courseId: widget.course['id']));
    context.read<ReviewBloc>().add(LoadCourseReviewSummary(courseId: widget.course['id']));
    context.read<ReviewBloc>().add(LoadUserReview(courseId: widget.course['id']));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is CourseReviewsLoaded) {
          setState(() {
            _reviews = state.reviews;
            _hasMoreReviews = state.hasMore;
            _isLoading = false;
          });
        } else if (state is CourseReviewSummaryLoaded) {
          setState(() {
            _summary = state.summary;
          });
        } else if (state is UserReviewLoaded) {
          setState(() {
            _userReview = state.userReview;
          });
        } else if (state is ReviewError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _loadReviews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reviews Header
              _buildReviewsHeader(),
              const SizedBox(height: 24),
              
              // Review Summary
              if (_summary != null) ...[
                ReviewSummaryWidget(
                  summary: _summary,
                  isDark: widget.isDark,
                  reviews: _reviews,
                ),
                const SizedBox(height: 24),
              ],

              // My Review Section
              if (_userReview != null) ...[
                _buildMyReviewSection(),
                const SizedBox(height: 24),
              ],

              // Reviews List
              _buildReviewsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use compact layout for small screens (< 360px width)
        final isSmallScreen = constraints.maxWidth < 360;

        if (isSmallScreen) {
          // Stack vertically on small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Reviews',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      final avgRating = _summary?.averageRating ?? 0.0;
                      return Icon(
                        index < avgRating.floor()
                            ? Icons.star_rounded
                            : index < avgRating
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_summary?.averageRating.toStringAsFixed(1) ?? '0.0'} (${_summary?.totalReviews ?? 0})',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Write Review Button - Full width on small screens
              SizedBox(
                width: double.infinity,
                child: Tooltip(
                  message: _canWriteReview()
                      ? (_userReview != null ? 'Edit your review' : 'Write a review')
                      : 'Purchase this course to write a review',
                  child: ElevatedButton.icon(
                    onPressed: _canWriteReview() ? _showReviewForm : null,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(_userReview != null ? 'Edit Review' : 'Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canWriteReview() ? AppTheme.primaryLight : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Normal layout for larger screens
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Reviews',
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Star Rating
                      Row(
                        children: List.generate(5, (index) {
                          final avgRating = _summary?.averageRating ?? 0.0;
                          return Icon(
                            index < avgRating.floor()
                                ? Icons.star_rounded
                                : index < avgRating
                                    ? Icons.star_half_rounded
                                    : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${_summary?.averageRating.toStringAsFixed(1) ?? '0.0'} (${_summary?.totalReviews ?? 0} reviews)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Write Review Button
            Tooltip(
              message: _canWriteReview()
                  ? (_userReview != null ? 'Edit your review' : 'Write a review')
                  : 'Purchase this course to write a review',
              child: ElevatedButton.icon(
                onPressed: _canWriteReview() ? _showReviewForm : null,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(_userReview != null ? 'Edit' : 'Write'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canWriteReview() ? AppTheme.primaryLight : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyReviewSection() {
    if (_userReview == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'My Review',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Edit Button
              IconButton(
                onPressed: () => _showReviewForm(existingReview: _userReview),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit Review',
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              // Delete Button
              IconButton(
                onPressed: () => _deleteReview(_userReview!.id),
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Delete Review',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < _userReview!.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${_userReview!.rating}/5',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          Text(
            _userReview!.comment,
            style: AppTextStyles.bodyMedium.copyWith(
              color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
              height: 1.6,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Date
          Text(
            'Reviewed ${_formatDate(_userReview!.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF9E9E9E),
              fontSize: 12,
            ),
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

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Filter out user's review from the list (shown separately in My Review section)
    final otherReviews = _reviews.where((review) => review.id != _userReview?.id).toList();

    if (_reviews.isEmpty) {
      return _buildEmptyState();
    }

    // If only user's review exists, show a message
    if (otherReviews.isEmpty && _userReview != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Be the next to share your thoughts!',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Reviews',
          style: AppTextStyles.h3.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),

        // Reviews List (excluding user's review)
        ...otherReviews.map((review) {
          return ReviewCard(
            review: review,
            isDark: widget.isDark,
            isCurrentUser: false,
            onEdit: () => _showReviewForm(existingReview: review),
            onDelete: () => _deleteReview(review.id),
          );
        }).toList(),
        
        // Load More Button
        if (_hasMoreReviews) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadMoreReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDark ? Colors.grey[700] : Colors.grey[200],
                foregroundColor: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
              child: const Text('Load More Reviews'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.reviews_outlined,
                size: 48,
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No reviews yet',
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts about this course!',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
              ),
              textAlign: TextAlign.center,
            ),
            if (_canWriteReview()) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showReviewForm,
                icon: const Icon(Icons.star, size: 18),
                label: const Text('Write First Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canWriteReview() {
    // Check if user has purchased the course
    return widget.hasPurchased;
  }

  void _showReviewForm({ReviewModel? existingReview}) {
    if (!_canWriteReview()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must purchase this course before writing a review'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewForm(
        courseId: widget.course['id'],
        isDark: widget.isDark,
        existingReview: existingReview,
        onSubmitted: () {
          // Reviews will be reloaded automatically via BLoC
        },
      ),
    );
  }

  void _deleteReview(String reviewId) {
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
                // Warning Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
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
                            Icons.delete_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Delete Review',
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
                        'Are you sure you want to delete your review?',
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
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This action cannot be undone',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkDialog ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                                  width: 1.5,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: isDarkDialog ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<ReviewBloc>().add(DeleteReview(
                                    reviewId: reviewId,
                                    courseId: widget.course['id'],
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
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

  void _loadMoreReviews() {
    context.read<ReviewBloc>().add(LoadMoreCourseReviews(courseId: widget.course['id']));
  }
}
