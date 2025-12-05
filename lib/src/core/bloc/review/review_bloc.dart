import 'package:flutter_bloc/flutter_bloc.dart';
import 'review_event.dart';
import 'review_state.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/models/review_model.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;

  ReviewBloc({
    required ReviewRepository reviewRepository,
  }) : _reviewRepository = reviewRepository,
       super(const ReviewInitial()) {
    
    // User Events
    on<LoadCourseReviews>(_onLoadCourseReviews);
    on<LoadMoreCourseReviews>(_onLoadMoreCourseReviews);
    on<LoadUserReview>(_onLoadUserReview);
    on<CreateOrUpdateReview>(_onCreateOrUpdateReview);
    on<DeleteReview>(_onDeleteReview);
    on<VoteForReview>(_onVoteForReview);
    on<ReportReview>(_onReportReview);
    on<LoadCourseReviewSummary>(_onLoadCourseReviewSummary);
    on<ResetReviewState>(_onResetReviewState);
    
    // Admin Events
    on<LoadAllReviews>(_onLoadAllReviews);
    on<ToggleReviewVisibility>(_onToggleReviewVisibility);
    on<AddAdminResponse>(_onAddAdminResponse);
    on<UpdateAllCourseRatings>(_onUpdateAllCourseRatings);
  }

  // User Event Handlers
  Future<void> _onLoadCourseReviews(
    LoadCourseReviews event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());

      final reviews = await _reviewRepository.getCourseReviews(
        courseId: event.courseId,
        limit: event.limit,
        sortBy: event.sortBy,
        ascending: event.ascending,
        onlyVerified: event.onlyVerified,
      );

      emit(CourseReviewsLoaded(
        reviews: reviews,
        hasMore: reviews.length >= event.limit,
        courseId: event.courseId,
      ));

      print('ReviewBloc: Loaded ${reviews.length} reviews for course ${event.courseId}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error loading course reviews: $e');
    }
  }

  Future<void> _onLoadMoreCourseReviews(
    LoadMoreCourseReviews event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      if (state is! CourseReviewsLoaded) return;

      final currentState = state as CourseReviewsLoaded;
      if (!currentState.hasMore) return;

      final lastReview = currentState.reviews.isNotEmpty 
          ? currentState.reviews.last 
          : null;

      // Get the last document for pagination
      // Note: In a real implementation, you'd need to track the last document
      // For now, we'll use a simplified approach
      final moreReviews = await _reviewRepository.getCourseReviews(
        courseId: event.courseId,
        limit: event.limit,
        sortBy: event.sortBy,
        ascending: event.ascending,
        onlyVerified: event.onlyVerified,
      );

      final allReviews = [...currentState.reviews, ...moreReviews];

      emit(MoreReviewsLoaded(
        allReviews: allReviews,
        hasMore: moreReviews.length >= event.limit,
        courseId: event.courseId,
      ));

      print('ReviewBloc: Loaded ${moreReviews.length} more reviews for course ${event.courseId}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error loading more reviews: $e');
    }
  }

  Future<void> _onLoadUserReview(
    LoadUserReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());

      final userReview = await _reviewRepository.getUserReviewForCourse(
        courseId: event.courseId,
        userId: event.userId,
      );

      emit(UserReviewLoaded(
        userReview: userReview,
        courseId: event.courseId,
      ));

      print('ReviewBloc: Loaded user review for course ${event.courseId}: ${userReview != null ? 'Found' : 'Not found'}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error loading user review: $e');
    }
  }

  Future<void> _onCreateOrUpdateReview(
    CreateOrUpdateReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());

      final review = await _reviewRepository.createOrUpdateReview(
        courseId: event.courseId,
        rating: event.rating,
        comment: event.comment,
      );

      // Check if this is a new review or update
      final currentState = state;
      if (currentState is UserReviewLoaded && currentState.userReview != null) {
        emit(ReviewUpdated(
          review: review,
          courseId: event.courseId,
        ));
      } else {
        emit(ReviewCreated(
          review: review,
          courseId: event.courseId,
        ));
      }

      // Reload reviews to show the new/updated review
      add(LoadCourseReviews(courseId: event.courseId));
      add(LoadCourseReviewSummary(courseId: event.courseId));

      print('ReviewBloc: Created/Updated review for course ${event.courseId}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error creating/updating review: $e');
    }
  }

  Future<void> _onDeleteReview(
    DeleteReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());

      // Use courseId from the event
      final courseId = event.courseId;

      await _reviewRepository.deleteReview(event.reviewId);

      emit(ReviewDeleted(
        reviewId: event.reviewId,
        courseId: courseId,
      ));

      // Always reload reviews and summary after deletion
      add(LoadCourseReviews(courseId: courseId));
      add(LoadCourseReviewSummary(courseId: courseId));
      add(LoadUserReview(courseId: courseId));

      print('ReviewBloc: Deleted review ${event.reviewId} from course $courseId');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error deleting review: $e');
    }
  }

  Future<void> _onVoteForReview(
    VoteForReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.voteForReview(
        reviewId: event.reviewId,
        isHelpful: event.isHelpful,
      );

      emit(ReviewVoted(
        reviewId: event.reviewId,
        isHelpful: event.isHelpful,
      ));

      print('ReviewBloc: Voted for review ${event.reviewId}: ${event.isHelpful ? 'helpful' : 'not helpful'}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error voting for review: $e');
    }
  }

  Future<void> _onReportReview(
    ReportReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.reportReview(event.reviewId);

      emit(ReviewReported(reviewId: event.reviewId));

      print('ReviewBloc: Reported review ${event.reviewId}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error reporting review: $e');
    }
  }

  Future<void> _onLoadCourseReviewSummary(
    LoadCourseReviewSummary event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      final summary = await _reviewRepository.getCourseReviewSummary(event.courseId);

      emit(CourseReviewSummaryLoaded(
        summary: summary,
        courseId: event.courseId,
      ));

      print('ReviewBloc: Loaded review summary for course ${event.courseId}: ${summary?.totalReviews ?? 0} reviews');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
        courseId: event.courseId,
      ));
      print('ReviewBloc: Error loading review summary: $e');
    }
  }

  Future<void> _onResetReviewState(
    ResetReviewState event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewInitial());
    print('ReviewBloc: Reset review state');
  }

  // Admin Event Handlers
  Future<void> _onLoadAllReviews(
    LoadAllReviews event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());

      final reviews = await _reviewRepository.getRecentReviews(
        limit: event.limit,
        onlyReported: event.onlyReported,
      );

      emit(AllReviewsLoaded(
        reviews: reviews,
        hasMore: reviews.length >= event.limit,
      ));

      print('ReviewBloc: Loaded ${reviews.length} reviews for admin');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error loading all reviews: $e');
    }
  }

  Future<void> _onToggleReviewVisibility(
    ToggleReviewVisibility event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.toggleReviewVisibility(
        event.reviewId,
        event.isVisible,
      );

      emit(ReviewVisibilityToggled(
        reviewId: event.reviewId,
        isVisible: event.isVisible,
      ));

      print('ReviewBloc: Toggled review ${event.reviewId} visibility to ${event.isVisible}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error toggling review visibility: $e');
    }
  }

  Future<void> _onAddAdminResponse(
    AddAdminResponse event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.addAdminResponse(
        reviewId: event.reviewId,
        response: event.response,
      );

      emit(AdminResponseAdded(
        reviewId: event.reviewId,
        response: event.response,
      ));

      print('ReviewBloc: Added admin response to review ${event.reviewId}');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error adding admin response: $e');
    }
  }

  Future<void> _onUpdateAllCourseRatings(
    UpdateAllCourseRatings event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      emit(const ReviewLoading());
      
      await _reviewRepository.updateAllCourseRatings();
      
      emit(const BulkUpdateCompleted());
      
      print('ReviewBloc: Completed bulk course rating update');
    } catch (e) {
      emit(ReviewError(
        error: e.toString(),
      ));
      print('ReviewBloc: Error in bulk course rating update: $e');
    }
  }
}
