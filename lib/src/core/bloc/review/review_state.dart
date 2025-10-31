import 'package:equatable/equatable.dart';
import '../../../data/models/review_model.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class CourseReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final bool hasMore;
  final String courseId;

  const CourseReviewsLoaded({
    required this.reviews,
    required this.hasMore,
    required this.courseId,
  });

  @override
  List<Object?> get props => [reviews, hasMore, courseId];
}

class MoreReviewsLoaded extends ReviewState {
  final List<ReviewModel> allReviews;
  final bool hasMore;
  final String courseId;

  const MoreReviewsLoaded({
    required this.allReviews,
    required this.hasMore,
    required this.courseId,
  });

  @override
  List<Object?> get props => [allReviews, hasMore, courseId];
}

class UserReviewLoaded extends ReviewState {
  final ReviewModel? userReview;
  final String courseId;

  const UserReviewLoaded({
    this.userReview,
    required this.courseId,
  });

  @override
  List<Object?> get props => [userReview, courseId];
}

class ReviewCreated extends ReviewState {
  final ReviewModel review;
  final String courseId;

  const ReviewCreated({
    required this.review,
    required this.courseId,
  });

  @override
  List<Object?> get props => [review, courseId];
}

class ReviewUpdated extends ReviewState {
  final ReviewModel review;
  final String courseId;

  const ReviewUpdated({
    required this.review,
    required this.courseId,
  });

  @override
  List<Object?> get props => [review, courseId];
}

class ReviewDeleted extends ReviewState {
  final String reviewId;
  final String courseId;

  const ReviewDeleted({
    required this.reviewId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [reviewId, courseId];
}

class ReviewVoted extends ReviewState {
  final String reviewId;
  final bool isHelpful;

  const ReviewVoted({
    required this.reviewId,
    required this.isHelpful,
  });

  @override
  List<Object?> get props => [reviewId, isHelpful];
}

class ReviewReported extends ReviewState {
  final String reviewId;

  const ReviewReported({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class CourseReviewSummaryLoaded extends ReviewState {
  final CourseReviewSummary? summary;
  final String courseId;

  const CourseReviewSummaryLoaded({
    this.summary,
    required this.courseId,
  });

  @override
  List<Object?> get props => [summary, courseId];
}

// Admin States
class AllReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final bool hasMore;

  const AllReviewsLoaded({
    required this.reviews,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [reviews, hasMore];
}

class ReviewVisibilityToggled extends ReviewState {
  final String reviewId;
  final bool isVisible;

  const ReviewVisibilityToggled({
    required this.reviewId,
    required this.isVisible,
  });

  @override
  List<Object?> get props => [reviewId, isVisible];
}

class AdminResponseAdded extends ReviewState {
  final String reviewId;
  final String response;

  const AdminResponseAdded({
    required this.reviewId,
    required this.response,
  });

  @override
  List<Object?> get props => [reviewId, response];
}

class BulkUpdateCompleted extends ReviewState {
  const BulkUpdateCompleted();

  @override
  List<Object?> get props => [];
}

class ReviewError extends ReviewState {
  final String error;
  final String? courseId;

  const ReviewError({
    required this.error,
    this.courseId,
  });

  @override
  List<Object?> get props => [error, courseId];
}
