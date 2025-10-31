import 'package:equatable/equatable.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

// Course CRUD Events
class LoadCourses extends CourseEvent {
  const LoadCourses();
}

class LoadCourse extends CourseEvent {
  final String courseId;

  const LoadCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class CreateCourse extends CourseEvent {
  final Map<String, dynamic> courseData;
  final String? thumbnailFile;
  final String? certificateFile;

  const CreateCourse({
    required this.courseData,
    this.thumbnailFile,
    this.certificateFile,
  });

  @override
  List<Object?> get props => [courseData, thumbnailFile, certificateFile];
}

class UpdateCourse extends CourseEvent {
  final String courseId;
  final Map<String, dynamic> courseData;
  final String? thumbnailFile;
  final String? certificateFile;
  final String? existingThumbnailUrl;
  final String? existingCertificateUrl;

  const UpdateCourse({
    required this.courseId,
    required this.courseData,
    this.thumbnailFile,
    this.certificateFile,
    this.existingThumbnailUrl,
    this.existingCertificateUrl,
  });

  @override
  List<Object?> get props => [courseId, courseData, thumbnailFile, certificateFile, existingThumbnailUrl, existingCertificateUrl];
}

class DeleteCourse extends CourseEvent {
  final String courseId;

  const DeleteCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

// Module Events
class LoadCourseModules extends CourseEvent {
  final String courseId;

  const LoadCourseModules(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class CreateModule extends CourseEvent {
  final String courseId;
  final Map<String, dynamic> moduleData;

  const CreateModule({
    required this.courseId,
    required this.moduleData,
  });

  @override
  List<Object?> get props => [courseId, moduleData];
}

class UpdateModule extends CourseEvent {
  final String courseId;
  final String moduleId;
  final Map<String, dynamic> moduleData;

  const UpdateModule({
    required this.courseId,
    required this.moduleId,
    required this.moduleData,
  });

  @override
  List<Object?> get props => [courseId, moduleId, moduleData];
}

class DeleteModule extends CourseEvent {
  final String courseId;
  final String moduleId;

  const DeleteModule({
    required this.courseId,
    required this.moduleId,
  });

  @override
  List<Object?> get props => [courseId, moduleId];
}

// Video Events
class LoadModuleVideos extends CourseEvent {
  final String courseId;
  final String moduleId;

  const LoadModuleVideos({
    required this.courseId,
    required this.moduleId,
  });

  @override
  List<Object?> get props => [courseId, moduleId];
}

class CreateVideo extends CourseEvent {
  final String courseId;
  final String moduleId;
  final Map<String, dynamic> videoData;
  final String videoFile;
  final String? thumbnailFile;

  const CreateVideo({
    required this.courseId,
    required this.moduleId,
    required this.videoData,
    required this.videoFile,
    this.thumbnailFile,
  });

  @override
  List<Object?> get props => [courseId, moduleId, videoData, videoFile, thumbnailFile];
}

class UpdateVideo extends CourseEvent {
  final String courseId;
  final String moduleId;
  final String videoId;
  final Map<String, dynamic> videoData;
  final String? videoFile;
  final String? thumbnailFile;

  const UpdateVideo({
    required this.courseId,
    required this.moduleId,
    required this.videoId,
    required this.videoData,
    this.videoFile,
    this.thumbnailFile,
  });

  @override
  List<Object?> get props => [courseId, moduleId, videoId, videoData, videoFile, thumbnailFile];
}

class DeleteVideo extends CourseEvent {
  final String courseId;
  final String moduleId;
  final String videoId;

  const DeleteVideo({
    required this.courseId,
    required this.moduleId,
    required this.videoId,
  });

  @override
  List<Object?> get props => [courseId, moduleId, videoId];
}

// Upload Events
class UploadCourseThumbnail extends CourseEvent {
  final String courseId;
  final String filePath;

  const UploadCourseThumbnail({
    required this.courseId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [courseId, filePath];
}

class UploadVideoFile extends CourseEvent {
  final String courseId;
  final String moduleId;
  final String videoId;
  final String filePath;

  const UploadVideoFile({
    required this.courseId,
    required this.moduleId,
    required this.videoId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [courseId, moduleId, videoId, filePath];
}

// Search and Filter Events
class SearchCourses extends CourseEvent {
  final String query;

  const SearchCourses(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCourses extends CourseEvent {
  final String filter;
  final String sortBy;

  const FilterCourses({
    required this.filter,
    required this.sortBy,
  });

  @override
  List<Object?> get props => [filter, sortBy];
}

// Course Statistics Events
class UpdateCourseTotalDuration extends CourseEvent {
  final String courseId;

  const UpdateCourseTotalDuration(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class RecalculateAllCourseDurations extends CourseEvent {
  const RecalculateAllCourseDurations();
}

// Reset Events
class ResetCourseState extends CourseEvent {
  const ResetCourseState();
}
