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

enum StarRatingFilter { all, five, four, three, two, one }

class CourseReviewsTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;

  const CourseReviewsTab({
    super.key,
    required this.course,
    required this.isDark,
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
  StarRatingFilter _selectedFilter = StarRatingFilter.all;

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

  List<ReviewModel> get _filteredReviews {
    switch (_selectedFilter) {
      case StarRatingFilter.all:
        return _reviews;
      case StarRatingFilter.five:
        return _reviews.where((review) => review.rating >= 4.5).toList();
      case StarRatingFilter.four:
        return _reviews.where((review) => review.rating >= 3.5 && review.rating < 4.5).toList();
      case StarRatingFilter.three:
        return _reviews.where((review) => review.rating >= 2.5 && review.rating < 3.5).toList();
      case StarRatingFilter.two:
        return _reviews.where((review) => review.rating >= 1.5 && review.rating < 2.5).toList();
      case StarRatingFilter.one:
        return _reviews.where((review) => review.rating < 1.5).toList();
    }
  }

  int _getReviewCountForRating(StarRatingFilter filter) {
    switch (filter) {
      case StarRatingFilter.all:
        return _reviews.length;
      case StarRatingFilter.five:
        return _reviews.where((review) => review.rating >= 4.5).length;
      case StarRatingFilter.four:
        return _reviews.where((review) => review.rating >= 3.5 && review.rating < 4.5).length;
      case StarRatingFilter.three:
        return _reviews.where((review) => review.rating >= 2.5 && review.rating < 3.5).length;
      case StarRatingFilter.two:
        return _reviews.where((review) => review.rating >= 1.5 && review.rating < 2.5).length;
      case StarRatingFilter.one:
        return _reviews.where((review) => review.rating < 1.5).length;
    }
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

              // Star Rating Filter Chips
              if (_reviews.isNotEmpty) ...[
                _buildStarRatingFilters(),
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

  Widget _buildStarRatingFilters() {
    // Build list of filter chips with counts
    final filterChips = <Widget>[];

    // Always add "All" chip
    filterChips.add(_buildStarFilterChip(
      label: 'All',
      filter: StarRatingFilter.all,
      icon: Icons.star_rounded,
    ));

    // Add 5 Stars chip if count > 0
    if (_getReviewCountForRating(StarRatingFilter.five) > 0) {
      filterChips.add(const SizedBox(width: 8));
      filterChips.add(_buildStarFilterChip(
        label: '5 Stars',
        filter: StarRatingFilter.five,
        icon: Icons.star,
      ));
    }

    // Add 4 Stars chip if count > 0
    if (_getReviewCountForRating(StarRatingFilter.four) > 0) {
      filterChips.add(const SizedBox(width: 8));
      filterChips.add(_buildStarFilterChip(
        label: '4 Stars',
        filter: StarRatingFilter.four,
        icon: Icons.star,
      ));
    }

    // Add 3 Stars chip if count > 0
    if (_getReviewCountForRating(StarRatingFilter.three) > 0) {
      filterChips.add(const SizedBox(width: 8));
      filterChips.add(_buildStarFilterChip(
        label: '3 Stars',
        filter: StarRatingFilter.three,
        icon: Icons.star,
      ));
    }

    // Add 2 Stars chip if count > 0
    if (_getReviewCountForRating(StarRatingFilter.two) > 0) {
      filterChips.add(const SizedBox(width: 8));
      filterChips.add(_buildStarFilterChip(
        label: '2 Stars',
        filter: StarRatingFilter.two,
        icon: Icons.star,
      ));
    }

    // Add 1 Star chip if count > 0
    if (_getReviewCountForRating(StarRatingFilter.one) > 0) {
      filterChips.add(const SizedBox(width: 8));
      filterChips.add(_buildStarFilterChip(
        label: '1 Star',
        filter: StarRatingFilter.one,
        icon: Icons.star,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Rating',
          style: AppTextStyles.bodyLarge.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterChips,
          ),
        ),
      ],
    );
  }

  Widget _buildStarFilterChip({
    required String label,
    required StarRatingFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;
    final count = _getReviewCountForRating(filter);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight
              : (widget.isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryLight
                : (widget.isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (filter == StarRatingFilter.all
                      ? (widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)
                      : Colors.amber),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Reviews',
                style: AppTextStyles.h3.copyWith(
                  color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      final avgRating = _summary?.averageRating ?? 0.0;
                      return Icon(
                        index < avgRating.floor()
                            ? Icons.star
                            : index < avgRating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_summary?.averageRating.toStringAsFixed(1) ?? '0.0'} (${_summary?.totalReviews ?? 0} reviews)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Write Review Button
        ElevatedButton.icon(
          onPressed: _canWriteReview() ? _showReviewForm : null,
          icon: const Icon(Icons.edit, size: 18),
          label: Text(_userReview != null ? 'Edit Review' : 'Write Review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
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

    if (_reviews.isEmpty) {
      return _buildEmptyState();
    }

    final filteredReviews = _filteredReviews;

    if (filteredReviews.isEmpty && _selectedFilter != StarRatingFilter.all) {
      return _buildNoReviewsForRating();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedFilter == StarRatingFilter.all
                  ? 'All Reviews'
                  : 'Filtered Reviews',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${filteredReviews.length} ${filteredReviews.length == 1 ? 'review' : 'reviews'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reviews List
        ...filteredReviews.map((review) {
          return ReviewCard(
            review: review,
            isDark: widget.isDark,
            isCurrentUser: _userReview?.id == review.id,
            onEdit: () => _showReviewForm(existingReview: review),
            onDelete: () => _deleteReview(review.id),
          );
        }).toList(),

        // Load More Button
        if (_hasMoreReviews && _selectedFilter == StarRatingFilter.all) ...[
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

  Widget _buildNoReviewsForRating() {
    String filterName = '';
    switch (_selectedFilter) {
      case StarRatingFilter.five:
        filterName = '5 stars';
        break;
      case StarRatingFilter.four:
        filterName = '4 stars';
        break;
      case StarRatingFilter.three:
        filterName = '3 stars';
        break;
      case StarRatingFilter.two:
        filterName = '2 stars';
        break;
      case StarRatingFilter.one:
        filterName = '1 star';
        break;
      default:
        filterName = 'this rating';
    }

    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (widget.isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off,
                size: 48,
                color: widget.isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $filterName reviews',
              style: AppTextStyles.h3.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different rating filter',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.reviews_outlined,
              size: 64,
              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts about this course!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
    // This should be implemented based on your course access logic
    return true; // For now, allow all users to review
  }

  void _showReviewForm({ReviewModel? existingReview}) {
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
                                  context.read<ReviewBloc>().add(DeleteReview(reviewId: reviewId));
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
