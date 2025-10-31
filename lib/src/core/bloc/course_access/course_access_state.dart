import 'package:equatable/equatable.dart';

abstract class CourseAccessState extends Equatable {
  const CourseAccessState();

  @override
  List<Object?> get props => [];
}

class CourseAccessInitial extends CourseAccessState {
  const CourseAccessInitial();
}

class CourseAccessLoading extends CourseAccessState {
  final String? courseId;

  const CourseAccessLoading({this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class CourseAccessChecked extends CourseAccessState {
  final String courseId;
  final bool hasAccess;

  const CourseAccessChecked({
    required this.courseId,
    required this.hasAccess,
  });

  @override
  List<Object?> get props => [courseId, hasAccess];
}

class PurchasedCoursesLoaded extends CourseAccessState {
  final List<String> purchasedCourses;

  const PurchasedCoursesLoaded({required this.purchasedCourses});

  @override
  List<Object?> get props => [purchasedCourses];
}

class PurchasedCoursesWithDetailsLoaded extends CourseAccessState {
  final List<Map<String, dynamic>> purchasedCourses;

  const PurchasedCoursesWithDetailsLoaded({required this.purchasedCourses});

  @override
  List<Object?> get props => [purchasedCourses];
}

class VideoAccessLoading extends CourseAccessState {
  final String courseId;
  final String? videoId;

  const VideoAccessLoading({
    required this.courseId,
    this.videoId,
  });

  @override
  List<Object?> get props => [courseId, videoId];
}

class VideoAccessChecked extends CourseAccessState {
  final String courseId;
  final String? videoId;
  final bool hasAccess;

  const VideoAccessChecked({
    required this.courseId,
    required this.hasAccess,
    this.videoId,
  });

  @override
  List<Object?> get props => [courseId, videoId, hasAccess];
}

class CourseAccessError extends CourseAccessState {
  final String error;
  final String? courseId;

  const CourseAccessError({
    required this.error,
    this.courseId,
  });

  @override
  List<Object?> get props => [error, courseId];
}
