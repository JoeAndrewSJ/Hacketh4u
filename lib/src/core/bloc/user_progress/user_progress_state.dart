import 'package:equatable/equatable.dart';
import '../../../data/models/user_progress_model.dart';

abstract class UserProgressState extends Equatable {
  const UserProgressState();

  @override
  List<Object?> get props => [];
}

class UserProgressInitial extends UserProgressState {
  const UserProgressInitial();

  @override
  List<Object?> get props => [];
}

class UserProgressLoading extends UserProgressState {
  const UserProgressLoading();

  @override
  List<Object?> get props => [];
}

class UserProgressLoaded extends UserProgressState {
  final UserProgressModel userProgress;

  const UserProgressLoaded({required this.userProgress});

  @override
  List<Object?> get props => [userProgress];
}

class AllUserProgressLoaded extends UserProgressState {
  final List<UserProgressModel> userProgresses;

  const AllUserProgressLoaded({required this.userProgresses});

  @override
  List<Object?> get props => [userProgresses];
}

class CourseProgressSummaryLoaded extends UserProgressState {
  final CourseProgressSummary summary;

  const CourseProgressSummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class UserProgressUpdated extends UserProgressState {
  final UserProgressModel userProgress;
  final String message;

  const UserProgressUpdated({
    required this.userProgress,
    required this.message,
  });

  @override
  List<Object?> get props => [userProgress, message];
}

class VideoProgressUpdated extends UserProgressState {
  final UserProgressModel userProgress;
  final String videoId;
  final double watchPercentage;

  const VideoProgressUpdated({
    required this.userProgress,
    required this.videoId,
    required this.watchPercentage,
  });

  @override
  List<Object?> get props => [userProgress, videoId, watchPercentage];
}

class CertificateDownloaded extends UserProgressState {
  final UserProgressModel userProgress;
  final String downloadUrl;

  const CertificateDownloaded({
    required this.userProgress,
    required this.downloadUrl,
  });

  @override
  List<Object?> get props => [userProgress, downloadUrl];
}

class CourseStructureSynced extends UserProgressState {
  final UserProgressModel userProgress;
  final String message;

  const CourseStructureSynced({
    required this.userProgress,
    required this.message,
  });

  @override
  List<Object?> get props => [userProgress, message];
}

class CourseStructureAutoSynced extends UserProgressState {
  final String courseId;
  final String message;

  const CourseStructureAutoSynced({
    required this.courseId,
    required this.message,
  });

  @override
  List<Object?> get props => [courseId, message];
}

class UserProgressError extends UserProgressState {
  final String error;
  final String? courseId;

  const UserProgressError({
    required this.error,
    this.courseId,
  });

  @override
  List<Object?> get props => [error, courseId];
}

class UserProgressSuccess extends UserProgressState {
  final String message;

  const UserProgressSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
