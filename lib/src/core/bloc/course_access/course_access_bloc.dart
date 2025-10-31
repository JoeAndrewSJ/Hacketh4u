import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/course_access_service.dart';
import '../../di/service_locator.dart';
import 'course_access_event.dart';
import 'course_access_state.dart';

class CourseAccessBloc extends Bloc<CourseAccessEvent, CourseAccessState> {
  final CourseAccessService _courseAccessService;

  CourseAccessBloc({
    required CourseAccessService courseAccessService,
  }) : _courseAccessService = courseAccessService,
       super(const CourseAccessInitial()) {
    on<CheckCourseAccess>(_onCheckCourseAccess);
    on<LoadPurchasedCourses>(_onLoadPurchasedCourses);
    on<LoadPurchasedCoursesWithDetails>(_onLoadPurchasedCoursesWithDetails);
    on<CheckVideoAccess>(_onCheckVideoAccess);
  }

  Future<void> _onCheckCourseAccess(
    CheckCourseAccess event,
    Emitter<CourseAccessState> emit,
  ) async {
    try {
      emit(CourseAccessLoading(courseId: event.courseId));

      final hasAccess = await _courseAccessService.hasCourseAccess(event.courseId);

      emit(CourseAccessChecked(
        courseId: event.courseId,
        hasAccess: hasAccess,
      ));

      print('CourseAccessBloc: Course access checked for ${event.courseId}: $hasAccess');
    } catch (e) {
      emit(CourseAccessError(
        courseId: event.courseId,
        error: 'Failed to check course access: $e',
      ));
      print('CourseAccessBloc: Error checking course access: $e');
    }
  }

  Future<void> _onLoadPurchasedCourses(
    LoadPurchasedCourses event,
    Emitter<CourseAccessState> emit,
  ) async {
    try {
      emit(const CourseAccessLoading());

      final purchasedCourses = await _courseAccessService.getPurchasedCourses();

      emit(PurchasedCoursesLoaded(purchasedCourses: purchasedCourses));

      print('CourseAccessBloc: Loaded ${purchasedCourses.length} purchased courses');
    } catch (e) {
      emit(CourseAccessError(error: 'Failed to load purchased courses: $e'));
      print('CourseAccessBloc: Error loading purchased courses: $e');
    }
  }

  Future<void> _onLoadPurchasedCoursesWithDetails(
    LoadPurchasedCoursesWithDetails event,
    Emitter<CourseAccessState> emit,
  ) async {
    try {
      print('CourseAccessBloc: Starting to load purchased courses with details');
      emit(const CourseAccessLoading());

      final purchasedCourses = await _courseAccessService.getPurchasedCoursesWithDetails();

      print('CourseAccessBloc: Service returned ${purchasedCourses.length} courses');
      emit(PurchasedCoursesWithDetailsLoaded(purchasedCourses: purchasedCourses));

      print('CourseAccessBloc: Emitted PurchasedCoursesWithDetailsLoaded with ${purchasedCourses.length} courses');
    } catch (e) {
      print('CourseAccessBloc: Error loading purchased courses with details: $e');
      emit(CourseAccessError(error: 'Failed to load purchased courses with details: $e'));
    }
  }

  Future<void> _onCheckVideoAccess(
    CheckVideoAccess event,
    Emitter<CourseAccessState> emit,
  ) async {
    try {
      emit(VideoAccessLoading(
        courseId: event.courseId,
        videoId: event.videoId,
      ));

      final hasAccess = await _courseAccessService.hasVideoAccess(
        event.courseId,
        event.videoId,
      );

      emit(VideoAccessChecked(
        courseId: event.courseId,
        videoId: event.videoId,
        hasAccess: hasAccess,
      ));

      print('CourseAccessBloc: Video access checked for ${event.videoId} in course ${event.courseId}: $hasAccess');
    } catch (e) {
      emit(CourseAccessError(
        courseId: event.courseId,
        error: 'Failed to check video access: $e',
      ));
      print('CourseAccessBloc: Error checking video access: $e');
    }
  }
}
