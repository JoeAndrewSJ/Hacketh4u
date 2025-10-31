import 'package:equatable/equatable.dart';

abstract class CourseAccessEvent extends Equatable {
  const CourseAccessEvent();

  @override
  List<Object?> get props => [];
}

class CheckCourseAccess extends CourseAccessEvent {
  final String courseId;

  const CheckCourseAccess({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class LoadPurchasedCourses extends CourseAccessEvent {
  const LoadPurchasedCourses();
}

class LoadPurchasedCoursesWithDetails extends CourseAccessEvent {
  const LoadPurchasedCoursesWithDetails();
}

class CheckVideoAccess extends CourseAccessEvent {
  final String courseId;
  final String? videoId;

  const CheckVideoAccess({
    required this.courseId,
    this.videoId,
  });

  @override
  List<Object?> get props => [courseId, videoId];
}
