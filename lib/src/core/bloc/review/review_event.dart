import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Load reviews for a specific course
class LoadCourseReviews extends ReviewEvent {
  final String courseId;
  final int limit;
  final String sortBy;
  final bool ascending;
  final bool onlyVerified;

  const LoadCourseReviews({
    required this.courseId,
    this.limit = 10,
    this.sortBy = 'createdAt',
    this.ascending = false,
    this.onlyVerified = false,
  });

  @override
  List<Object?> get props => [courseId, limit, sortBy, ascending, onlyVerified];
}

/// Load more reviews (pagination)
class LoadMoreCourseReviews extends ReviewEvent {
  final String courseId;
  final int limit;
  final String sortBy;
  final bool ascending;
  final bool onlyVerified;

  const LoadMoreCourseReviews({
    required this.courseId,
    this.limit = 10,
    this.sortBy = 'createdAt',
    this.ascending = false,
    this.onlyVerified = false,
  });

  @override
  List<Object?> get props => [courseId, limit, sortBy, ascending, onlyVerified];
}

/// Load user's review for a specific course
class LoadUserReview extends ReviewEvent {
  final String courseId;
  final String? userId;

  const LoadUserReview({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Create or update a review
class CreateOrUpdateReview extends ReviewEvent {
  final String courseId;
  final int rating;
  final String comment;

  const CreateOrUpdateReview({
    required this.courseId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [courseId, rating, comment];
}

/// Delete a review
class DeleteReview extends ReviewEvent {
  final String reviewId;
  final String courseId;

  const DeleteReview({
    required this.reviewId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [reviewId, courseId];
}

/// Vote for a review (helpful/not helpful)
class VoteForReview extends ReviewEvent {
  final String reviewId;
  final bool isHelpful;

  const VoteForReview({
    required this.reviewId,
    required this.isHelpful,
  });

  @override
  List<Object?> get props => [reviewId, isHelpful];
}

/// Report a review
class ReportReview extends ReviewEvent {
  final String reviewId;

  const ReportReview({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Load course review summary
class LoadCourseReviewSummary extends ReviewEvent {
  final String courseId;

  const LoadCourseReviewSummary({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Reset review state
class ResetReviewState extends ReviewEvent {
  const ResetReviewState();
}

// Admin Events
/// Load all reviews for admin management
class LoadAllReviews extends ReviewEvent {
  final int limit;
  final bool onlyReported;

  const LoadAllReviews({
    this.limit = 50,
    this.onlyReported = false,
  });

  @override
  List<Object?> get props => [limit, onlyReported];
}

/// Toggle review visibility (admin)
class ToggleReviewVisibility extends ReviewEvent {
  final String reviewId;
  final bool isVisible;

  const ToggleReviewVisibility({
    required this.reviewId,
    required this.isVisible,
  });

  @override
  List<Object?> get props => [reviewId, isVisible];
}

/// Add admin response to a review
class AddAdminResponse extends ReviewEvent {
  final String reviewId;
  final String response;

  const AddAdminResponse({
    required this.reviewId,
    required this.response,
  });

  @override
  List<Object?> get props => [reviewId, response];
}

/// Bulk update all course ratings (admin utility)
class UpdateAllCourseRatings extends ReviewEvent {
  const UpdateAllCourseRatings();

  @override
  List<Object?> get props => [];
}
