import 'package:flutter_bloc/flutter_bloc.dart';
import 'course_event.dart';
import 'course_state.dart';
import '../../../data/repositories/course_repository.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository _courseRepository;

  CourseBloc({required CourseRepository courseRepository})
      : _courseRepository = courseRepository,
        super(const CourseState()) {
    
    // Course CRUD
    on<LoadCourses>(_onLoadCourses);
    on<LoadCourse>(_onLoadCourse);
    on<CreateCourse>(_onCreateCourse);
    on<UpdateCourse>(_onUpdateCourse);
    on<DeleteCourse>(_onDeleteCourse);
    
    // Module CRUD
    on<LoadCourseModules>(_onLoadCourseModules);
    on<LoadCourseModulesWithVideos>(_onLoadCourseModulesWithVideos);
    on<CreateModule>(_onCreateModule);
    on<UpdateModule>(_onUpdateModule);
    on<DeleteModule>(_onDeleteModule);
    
    // Video CRUD
    on<LoadModuleVideos>(_onLoadModuleVideos);
    on<CreateVideo>(_onCreateVideo);
    on<UpdateVideo>(_onUpdateVideo);
    on<DeleteVideo>(_onDeleteVideo);
    
    // Upload operations
    on<UploadCourseThumbnail>(_onUploadCourseThumbnail);
    on<UploadVideoFile>(_onUploadVideoFile);
    
    // Search and filter
    on<SearchCourses>(_onSearchCourses);
    on<FilterCourses>(_onFilterCourses);
    
    // Course statistics
    on<UpdateCourseTotalDuration>(_onUpdateCourseTotalDuration);
    on<RecalculateAllCourseDurations>(_onRecalculateAllCourseDurations);
    
    // Reset
    on<ResetCourseState>(_onResetCourseState);
  }

  Future<void> _onLoadCourses(LoadCourses event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final courses = await _courseRepository.getAllCourses();
      print('CourseBloc: Loaded ${courses.length} courses from Firebase');
      emit(state.copyWith(
        isLoading: false,
        courses: courses,
      ));
      emit(CourseLoaded(courses: courses));
    } catch (e) {
      print('CourseBloc: Error loading courses: $e');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      emit(CourseError(error: e.toString()));
    }
  }

  Future<void> _onLoadCourse(LoadCourse event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final course = await _courseRepository.getCourseById(event.courseId);
      emit(state.copyWith(
        isLoading: false,
        selectedCourse: course,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateCourse(CreateCourse event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      String? thumbnailUrl;
      String? certificateUrl;
      
      // Upload thumbnail if provided
      if (event.thumbnailFile != null) {
        thumbnailUrl = await _courseRepository.uploadThumbnail(
          event.thumbnailFile!,
          'course_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Upload certificate if provided
      if (event.certificateFile != null) {
        certificateUrl = await _courseRepository.uploadCertificate(
          event.certificateFile!,
          'certificate_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Add URLs to course data
      final courseData = Map<String, dynamic>.from(event.courseData);
      if (thumbnailUrl != null) {
        courseData['thumbnailUrl'] = thumbnailUrl;
      }
      if (certificateUrl != null) {
        courseData['certificateTemplateUrl'] = certificateUrl;
      }
      
      final course = await _courseRepository.createCourse(courseData);
      
      emit(state.copyWith(
        isLoading: false,
        courses: [...state.courses, course],
      ));
      
      emit(CourseCreated(course: course));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateCourse(UpdateCourse event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      String? thumbnailUrl;
      String? certificateUrl;
      
      // Upload new thumbnail if provided
      if (event.thumbnailFile != null) {
        thumbnailUrl = await _courseRepository.uploadThumbnail(
          event.thumbnailFile!,
          'course_${event.courseId}_${DateTime.now().millisecondsSinceEpoch}',
          existingUrl: event.existingThumbnailUrl,
        );
      }
      
      // Upload new certificate if provided
      if (event.certificateFile != null) {
        certificateUrl = await _courseRepository.uploadCertificate(
          event.certificateFile!,
          'certificate_${event.courseId}_${DateTime.now().millisecondsSinceEpoch}',
          existingUrl: event.existingCertificateUrl,
        );
      }
      
      // Add URLs to course data
      final courseData = Map<String, dynamic>.from(event.courseData);
      if (thumbnailUrl != null) {
        courseData['thumbnailUrl'] = thumbnailUrl;
      }
      if (certificateUrl != null) {
        courseData['certificateTemplateUrl'] = certificateUrl;
      }
      
      final course = await _courseRepository.updateCourse(event.courseId, courseData);
      
      // Update course in list
      final updatedCourses = state.courses.map((c) {
        if (c['id'] == event.courseId) {
          return course;
        }
        return c;
      }).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        courses: updatedCourses,
        selectedCourse: course,
      ));
      
      emit(CourseUpdated(course: course));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteCourse(DeleteCourse event, Emitter<CourseState> emit) async {
    print('CourseBloc: Starting deletion of course: ${event.courseId}');
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      await _courseRepository.deleteCourse(event.courseId);
      print('CourseBloc: Course deleted from repository: ${event.courseId}');
      
      // Remove course from list
      final updatedCourses = state.courses.where((c) => c['id'] != event.courseId).cast<Map<String, dynamic>>().toList();
      print('CourseBloc: Updated courses list, removed course: ${event.courseId}');
      
      emit(state.copyWith(
        isLoading: false,
        courses: updatedCourses,
        selectedCourse: state.selectedCourse?['id'] == event.courseId ? null : state.selectedCourse,
      ));
      
      emit(CourseDeleted(courseId: event.courseId));
      print('CourseBloc: Emitted CourseDeleted state for: ${event.courseId}');
    } catch (e) {
      print('CourseBloc: Error deleting course: $e');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      emit(CourseError(error: e.toString()));
    }
  }

  Future<void> _onLoadCourseModules(LoadCourseModules event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final modules = await _courseRepository.getCourseModules(event.courseId);
      emit(state.copyWith(
        isLoading: false,
        modules: modules,
      ));
      emit(ModulesLoaded(modules: modules));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      emit(CourseError(error: e.toString()));
    }
  }

  Future<void> _onLoadCourseModulesWithVideos(LoadCourseModulesWithVideos event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final modules = await _courseRepository.getCourseModulesWithVideos(event.courseId);
      emit(state.copyWith(
        isLoading: false,
        modules: modules,
      ));
      emit(ModulesLoaded(modules: modules));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      emit(CourseError(error: e.toString()));
    }
  }

  Future<void> _onCreateModule(CreateModule event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final module = await _courseRepository.createModule(event.courseId, event.moduleData);
      
      // Update course total duration
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      emit(state.copyWith(
        isLoading: false,
        modules: [...state.modules, module],
      ));
      
      emit(ModuleCreated(module: module));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateModule(UpdateModule event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final module = await _courseRepository.updateModule(
        event.courseId,
        event.moduleId,
        event.moduleData,
      );
      
      // Update course total duration
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      // Update module in list
      final updatedModules = state.modules.map((m) {
        if (m['id'] == event.moduleId) {
          return module;
        }
        return m;
      }).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        modules: updatedModules,
      ));
      
      emit(ModuleUpdated(module: module));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteModule(DeleteModule event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      await _courseRepository.deleteModule(event.courseId, event.moduleId);
      
      // Update course total duration
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      // Remove module from list
      final updatedModules = state.modules.where((m) => m['id'] != event.moduleId).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        modules: updatedModules,
      ));
      
      emit(ModuleDeleted(moduleId: event.moduleId));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadModuleVideos(LoadModuleVideos event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final videos = await _courseRepository.getModuleVideos(event.courseId, event.moduleId);
      emit(state.copyWith(
        isLoading: false,
        videos: videos,
      ));
      emit(VideosLoaded(videos: videos));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      emit(CourseError(error: e.toString()));
    }
  }

  Future<void> _onCreateVideo(CreateVideo event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, isUploading: true, error: null));
    
    try {
      String? videoUrl;
      String? thumbnailUrl;
      int duration = 0;
      
      // Get video duration
      duration = await _courseRepository.getVideoDuration(event.videoFile);
      
      // Upload video file
      videoUrl = await _courseRepository.uploadVideo(
        event.videoFile,
        '${event.courseId}/${event.moduleId}/${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Upload thumbnail if provided
      if (event.thumbnailFile != null) {
        thumbnailUrl = await _courseRepository.uploadVideoThumbnail(
          event.thumbnailFile!,
          '${event.courseId}/${event.moduleId}/${DateTime.now().millisecondsSinceEpoch}_thumb',
        );
      }
      
      // Add URLs and duration to video data
      final videoData = Map<String, dynamic>.from(event.videoData);
      videoData['videoUrl'] = videoUrl;
      videoData['duration'] = duration;
      if (thumbnailUrl != null) {
        videoData['thumbnailUrl'] = thumbnailUrl;
      }
      
      final video = await _courseRepository.createVideo(
        event.courseId,
        event.moduleId,
        videoData,
      );
      
      // Update course total duration (this is also called in repository, but ensuring it's updated)
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      emit(state.copyWith(
        isLoading: false,
        isUploading: false,
        videos: [...state.videos, video],
      ));
      
      emit(VideoCreated(video: video));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isUploading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateVideo(UpdateVideo event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      String? videoUrl;
      String? thumbnailUrl;
      
      // Upload new video file if provided
      if (event.videoFile != null) {
        videoUrl = await _courseRepository.uploadVideo(
          event.videoFile!,
          '${event.courseId}/${event.moduleId}/${event.videoId}',
        );
      }
      
      // Upload new thumbnail if provided
      if (event.thumbnailFile != null) {
        thumbnailUrl = await _courseRepository.uploadVideoThumbnail(
          event.thumbnailFile!,
          '${event.courseId}/${event.moduleId}/${event.videoId}_thumb',
        );
      }
      
      // Add URLs to video data
      final videoData = Map<String, dynamic>.from(event.videoData);
      if (videoUrl != null) {
        videoData['videoUrl'] = videoUrl;
      }
      if (thumbnailUrl != null) {
        videoData['thumbnailUrl'] = thumbnailUrl;
      }
      
      final video = await _courseRepository.updateVideo(
        event.courseId,
        event.moduleId,
        event.videoId,
        videoData,
      );
      
      // Update course total duration (this is also called in repository, but ensuring it's updated)
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      // Update video in list
      final updatedVideos = state.videos.map((v) {
        if (v['id'] == event.videoId) {
          return video;
        }
        return v;
      }).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        videos: updatedVideos,
      ));
      
      emit(VideoUpdated(video: video));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteVideo(DeleteVideo event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      await _courseRepository.deleteVideo(event.courseId, event.moduleId, event.videoId);
      
      // Update course total duration (this is also called in repository, but ensuring it's updated)
      await _courseRepository.updateCourseTotalDuration(event.courseId);
      
      // Remove video from list
      final updatedVideos = state.videos.where((v) => v['id'] != event.videoId).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        videos: updatedVideos,
      ));
      
      emit(VideoDeleted(videoId: event.videoId));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUploadCourseThumbnail(UploadCourseThumbnail event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isUploading: true, error: null));
    
    try {
      final url = await _courseRepository.uploadThumbnail(
        event.filePath,
        'course_${event.courseId}',
      );
      
      emit(state.copyWith(isUploading: false));
      emit(CourseFileUploaded(fileUrl: url));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUploadVideoFile(UploadVideoFile event, Emitter<CourseState> emit) async {
    emit(state.copyWith(isUploading: true, error: null));
    
    try {
      final url = await _courseRepository.uploadVideo(
        event.filePath,
        '${event.courseId}/${event.moduleId}/${event.videoId}',
      );
      
      emit(state.copyWith(isUploading: false));
      emit(CourseFileUploaded(fileUrl: url));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSearchCourses(SearchCourses event, Emitter<CourseState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    
    try {
      final courses = await _courseRepository.searchCourses(event.query);
      emit(state.copyWith(courses: courses));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFilterCourses(FilterCourses event, Emitter<CourseState> emit) async {
    emit(state.copyWith(filter: event.filter, sortBy: event.sortBy));
    
    try {
      final courses = await _courseRepository.filterCourses(event.filter, event.sortBy);
      emit(state.copyWith(courses: courses));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateCourseTotalDuration(UpdateCourseTotalDuration event, Emitter<CourseState> emit) async {
    try {
      await _courseRepository.updateCourseTotalDuration(event.courseId);
    } catch (e) {
      print('Error updating course total duration: $e');
    }
  }

  Future<void> _onRecalculateAllCourseDurations(RecalculateAllCourseDurations event, Emitter<CourseState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      // Get all courses
      final courses = await _courseRepository.getAllCourses();
      
      // Recalculate duration for each course
      for (final course in courses) {
        await _courseRepository.updateCourseTotalDuration(course['id']);
      }
      
      emit(state.copyWith(isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onResetCourseState(ResetCourseState event, Emitter<CourseState> emit) async {
    emit(const CourseState());
  }
}
