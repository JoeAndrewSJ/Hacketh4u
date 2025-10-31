import 'package:equatable/equatable.dart';

class CourseState extends Equatable {
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final List<Map<String, dynamic>> courses;
  final Map<String, dynamic>? selectedCourse;
  final List<Map<String, dynamic>> modules;
  final List<Map<String, dynamic>> videos;
  final String searchQuery;
  final String filter;
  final String sortBy;

  const CourseState({
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.courses = const [],
    this.selectedCourse,
    this.modules = const [],
    this.videos = const [],
    this.searchQuery = '',
    this.filter = 'all',
    this.sortBy = 'newest',
  });

  CourseState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? error,
    List<Map<String, dynamic>>? courses,
    Map<String, dynamic>? selectedCourse,
    List<Map<String, dynamic>>? modules,
    List<Map<String, dynamic>>? videos,
    String? searchQuery,
    String? filter,
    String? sortBy,
  }) {
    return CourseState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      modules: modules ?? this.modules,
      videos: videos ?? this.videos,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isUploading,
        error,
        courses,
        selectedCourse,
        modules,
        videos,
        searchQuery,
        filter,
        sortBy,
      ];
}

// Success States
class CourseLoaded extends CourseState {
  final List<Map<String, dynamic>> courses;

  const CourseLoaded({required this.courses}) : super(courses: courses);

  @override
  List<Object?> get props => [courses];
}

class ModulesLoaded extends CourseState {
  final List<Map<String, dynamic>> modules;

  const ModulesLoaded({required this.modules}) : super(modules: modules);

  @override
  List<Object?> get props => [modules];
}

class VideosLoaded extends CourseState {
  final List<Map<String, dynamic>> videos;

  const VideosLoaded({required this.videos}) : super(videos: videos);

  @override
  List<Object?> get props => [videos];
}

class CourseCreated extends CourseState {
  final Map<String, dynamic> course;

  const CourseCreated({required this.course}) : super();

  @override
  List<Object?> get props => [course];
}

class CourseUpdated extends CourseState {
  final Map<String, dynamic> course;

  const CourseUpdated({required this.course}) : super();

  @override
  List<Object?> get props => [course];
}

class CourseDeleted extends CourseState {
  final String courseId;

  const CourseDeleted({required this.courseId}) : super();

  @override
  List<Object?> get props => [courseId];
}

class ModuleCreated extends CourseState {
  final Map<String, dynamic> module;

  const ModuleCreated({required this.module}) : super();

  @override
  List<Object?> get props => [module];
}

class ModuleUpdated extends CourseState {
  final Map<String, dynamic> module;

  const ModuleUpdated({required this.module}) : super();

  @override
  List<Object?> get props => [module];
}

class ModuleDeleted extends CourseState {
  final String moduleId;

  const ModuleDeleted({required this.moduleId}) : super();

  @override
  List<Object?> get props => [moduleId];
}

class VideoCreated extends CourseState {
  final Map<String, dynamic> video;

  const VideoCreated({required this.video}) : super();

  @override
  List<Object?> get props => [video];
}

class VideoUpdated extends CourseState {
  final Map<String, dynamic> video;

  const VideoUpdated({required this.video}) : super();

  @override
  List<Object?> get props => [video];
}

class VideoDeleted extends CourseState {
  final String videoId;

  const VideoDeleted({required this.videoId}) : super();

  @override
  List<Object?> get props => [videoId];
}

class CourseFileUploaded extends CourseState {
  final String fileUrl;

  const CourseFileUploaded({required this.fileUrl}) : super();

  @override
  List<Object?> get props => [fileUrl];
}

// Error States
class CourseError extends CourseState {
  final String error;

  const CourseError({required this.error}) : super(error: error);

  @override
  List<Object?> get props => [error];
}
