import 'package:equatable/equatable.dart';

abstract class UserProgressEvent extends Equatable {
  const UserProgressEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize user progress when they purchase a course
class InitializeUserProgress extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const InitializeUserProgress({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Update video progress
class UpdateVideoProgress extends UserProgressEvent {
  final String courseId;
  final String moduleId;
  final String videoId;
  final double watchPercentage;
  final Duration watchedDuration;
  final String? userId;

  const UpdateVideoProgress({
    required this.courseId,
    required this.moduleId,
    required this.videoId,
    required this.watchPercentage,
    required this.watchedDuration,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, moduleId, videoId, watchPercentage, watchedDuration, userId];
}

/// Load user progress for a specific course
class LoadUserProgress extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const LoadUserProgress({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Load all user progress
class LoadAllUserProgress extends UserProgressEvent {
  final String? userId;

  const LoadAllUserProgress({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Sync course structure (when modules/videos are added/deleted)
class SyncCourseStructure extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const SyncCourseStructure({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Auto-sync course structure when videos are added/updated/deleted (admin utility)
class AutoSyncCourseStructure extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const AutoSyncCourseStructure({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Mark certificate as downloaded
class MarkCertificateDownloaded extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const MarkCertificateDownloaded({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Get course progress summary for certificate eligibility
class GetCourseProgressSummary extends UserProgressEvent {
  final String courseId;
  final String? userId;

  const GetCourseProgressSummary({
    required this.courseId,
    this.userId,
  });

  @override
  List<Object?> get props => [courseId, userId];
}

/// Reset user progress state
class ResetUserProgressState extends UserProgressEvent {
  const ResetUserProgressState();

  @override
  List<Object?> get props => [];
}
