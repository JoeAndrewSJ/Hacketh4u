import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/review/review_bloc.dart';
import '../../../core/bloc/review/review_event.dart';
import '../../../core/bloc/review/review_state.dart';
import '../../../data/models/review_model.dart';

class CourseReviewsListScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseReviewsListScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseReviewsListScreen> createState() => _CourseReviewsListScreenState();
}

class _CourseReviewsListScreenState extends State<CourseReviewsListScreen> {
  bool _isSelectionMode = false;
  Set<String> _selectedReviews = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    context.read<ReviewBloc>().add(LoadCourseReviews(courseId: widget.course['id'] ?? ''));
  }

  AppBar _buildNormalAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course['title'] ?? 'Untitled Course',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.course['totalReviews'] ?? 0} reviews',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryLight,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          onPressed: _loadReviews,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  AppBar _buildSelectionAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      title: Text('${_selectedReviews.length} selected', style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.primaryLight,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 22),
        onPressed: _exitSelectionMode,
      ),
      actions: [
        if (_selectedReviews.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            onPressed: _showBulkDeleteDialog,
            tooltip: 'Delete Selected',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedReviews.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReviews.clear();
    });
  }

  void _toggleReviewSelection(String reviewId) {
    setState(() {
      if (_selectedReviews.contains(reviewId)) {
        _selectedReviews.remove(reviewId);
      } else {
        _selectedReviews.add(reviewId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar(isDark) : _buildNormalAppBar(isDark),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } else if (state is ReviewDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Review deleted'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            _loadReviews();
            if (_isSelectionMode) {
              _exitSelectionMode();
            }
          }
        },
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is CourseReviewsLoaded) {
            if (state.reviews.isEmpty) {
              return _buildEmptyState(context, isDark);
            }
            return _buildReviewsList(context, state.reviews, isDark);
          } else if (state is ReviewError) {
            return _buildErrorState(context, state.error, isDark);
          }
          return _buildEmptyState(context, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<ReviewModel> reviews, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(context, review, isDark);
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review, bool isDark) {
    final isSelected = _selectedReviews.contains(review.id);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleReviewSelection(review.id);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode();
          _toggleReviewSelection(review.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected && _isSelectionMode
            ? AppTheme.primaryLight.withOpacity(0.08)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with selection overlay
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isSelectionMode)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryLight
                            : Colors.black.withOpacity(0.3),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : null,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Review content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, date, and rating row
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: review.userName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: '  •  ${_formatDate(review.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isSelectionMode) ...[
                        const SizedBox(width: 8),
                        // More options button
                        InkWell(
                          onTap: () => _showDeleteReviewDialog(review),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating stars
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber[700],
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        '${review.rating}.0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Comment text
                  Text(
                    review.comment,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteReviewDialog(ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete review?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[800],
                ),
                children: [
                  const TextSpan(text: 'Delete review by '),
                  TextSpan(
                    text: review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '? This action cannot be undone.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ReviewBloc>().add(DeleteReview(
                reviewId: review.id,
                courseId: review.courseId,
              ));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    if (_selectedReviews.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${_selectedReviews.length} review${_selectedReviews.length > 1 ? 's' : ''}?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete the selected review${_selectedReviews.length > 1 ? 's' : ''}. This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedReviews();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedReviews() {
    final courseId = widget.course['id'] as String;
    for (final reviewId in _selectedReviews) {
      context.read<ReviewBloc>().add(DeleteReview(
        reviewId: reviewId,
        courseId: courseId,
      ));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
