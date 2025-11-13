import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_progress_event.dart';
import 'user_progress_state.dart';
import '../../../data/repositories/user_progress_repository.dart';
import '../../../data/models/user_progress_model.dart';

class UserProgressBloc extends Bloc<UserProgressEvent, UserProgressState> {
  final UserProgressRepository _userProgressRepository;

  UserProgressBloc({required UserProgressRepository userProgressRepository})
      : _userProgressRepository = userProgressRepository,
        super(const UserProgressInitial()) {
    
    // Event handlers
    on<InitializeUserProgress>(_onInitializeUserProgress);
    on<UpdateVideoProgress>(_onUpdateVideoProgress);
    on<LoadUserProgress>(_onLoadUserProgress);
    on<LoadAllUserProgress>(_onLoadAllUserProgress);
    on<SyncCourseStructure>(_onSyncCourseStructure);
    on<AutoSyncCourseStructure>(_onAutoSyncCourseStructure);
    on<MarkCertificateDownloaded>(_onMarkCertificateDownloaded);
    on<GetCourseProgressSummary>(_onGetCourseProgressSummary);
    on<ResetUserProgressState>(_onResetUserProgressState);
  }

  Future<void> _onInitializeUserProgress(
    InitializeUserProgress event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      final userProgress = await _userProgressRepository.initializeUserProgress(
        courseId: event.courseId,
        userId: event.userId,
      );

      emit(UserProgressUpdated(
        userProgress: userProgress,
        message: 'User progress initialized successfully',
      ));

      print('UserProgressBloc: Initialized progress for user ${event.userId ?? 'current'}, course ${event.courseId}');
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to initialize user progress: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error initializing user progress: $e');
    }
  }

  Future<void> _onUpdateVideoProgress(
    UpdateVideoProgress event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      await _userProgressRepository.updateVideoProgress(
        courseId: event.courseId,
        moduleId: event.moduleId,
        videoId: event.videoId,
        watchPercentage: event.watchPercentage,
        watchedDuration: event.watchedDuration,
        userId: event.userId,
      );

      // Reload user progress to get updated data
      final updatedProgress = await _userProgressRepository.getUserProgress(
        courseId: event.courseId,
        userId: event.userId,
      );

      if (updatedProgress != null) {
        emit(VideoProgressUpdated(
          userProgress: updatedProgress,
          videoId: event.videoId,
          watchPercentage: event.watchPercentage,
        ));

        print('UserProgressBloc: Updated video progress for video ${event.videoId} - ${event.watchPercentage}%');
      }
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to update video progress: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error updating video progress: $e');
    }
  }

  Future<void> _onLoadUserProgress(
    LoadUserProgress event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      final userProgress = await _userProgressRepository.getUserProgress(
        courseId: event.courseId,
        userId: event.userId,
      );

      if (userProgress != null) {
        emit(UserProgressLoaded(userProgress: userProgress));
        print('UserProgressBloc: Loaded progress for user ${event.userId ?? 'current'}, course ${event.courseId}');
      } else {
        emit(const UserProgressError(
          error: 'User progress not found',
        ));
        print('UserProgressBloc: No progress found for user ${event.userId ?? 'current'}, course ${event.courseId}');
      }
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to load user progress: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error loading user progress: $e');
    }
  }

  Future<void> _onLoadAllUserProgress(
    LoadAllUserProgress event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      final userProgresses = await _userProgressRepository.getAllUserProgress(
        userId: event.userId,
      );

      emit(AllUserProgressLoaded(userProgresses: userProgresses));
      print('UserProgressBloc: Loaded ${userProgresses.length} progress records for user ${event.userId ?? 'current'}');
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to load all user progress: $e',
      ));
      print('UserProgressBloc: Error loading all user progress: $e');
    }
  }

  Future<void> _onSyncCourseStructure(
    SyncCourseStructure event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      await _userProgressRepository.syncCourseStructure(
        courseId: event.courseId,
        userId: event.userId,
      );

      // Reload user progress to get updated data
      final updatedProgress = await _userProgressRepository.getUserProgress(
        courseId: event.courseId,
        userId: event.userId,
      );

      if (updatedProgress != null) {
        emit(CourseStructureSynced(
          userProgress: updatedProgress,
          message: 'Course structure synced successfully',
        ));

        print('UserProgressBloc: Synced course structure for user ${event.userId ?? 'current'}, course ${event.courseId}');
      }
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to sync course structure: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error syncing course structure: $e');
    }
  }

  Future<void> _onAutoSyncCourseStructure(
    AutoSyncCourseStructure event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      await _userProgressRepository.autoSyncCourseStructure(
        courseId: event.courseId,
        userId: event.userId,
      );

      emit(CourseStructureAutoSynced(
        courseId: event.courseId,
        message: 'Course structure auto-synced successfully',
      ));

      print('UserProgressBloc: Auto-synced course structure for user ${event.userId ?? 'current'}, course ${event.courseId}');
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to auto-sync course structure: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error auto-syncing course structure: $e');
    }
  }

  Future<void> _onMarkCertificateDownloaded(
    MarkCertificateDownloaded event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      await _userProgressRepository.markCertificateDownloaded(
        courseId: event.courseId,
        certificateNumber: event.certificateNumber,
        issueDate: event.issueDate,
        userId: event.userId,
      );

      // Get course progress summary for certificate URL
      final summary = await _userProgressRepository.getCourseProgressSummary(
        courseId: event.courseId,
        userId: event.userId,
      );

      // Reload user progress to get updated data
      final updatedProgress = await _userProgressRepository.getUserProgress(
        courseId: event.courseId,
        userId: event.userId,
      );

      if (updatedProgress != null && summary.certificateTemplateUrl != null) {
        emit(CertificateDownloaded(
          userProgress: updatedProgress,
          downloadUrl: summary.certificateTemplateUrl!,
        ));

        print('UserProgressBloc: Marked certificate as downloaded for user ${event.userId ?? 'current'}, course ${event.courseId}');
      }
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to mark certificate as downloaded: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error marking certificate as downloaded: $e');
    }
  }

  Future<void> _onGetCourseProgressSummary(
    GetCourseProgressSummary event,
    Emitter<UserProgressState> emit,
  ) async {
    try {
      emit(const UserProgressLoading());

      final summary = await _userProgressRepository.getCourseProgressSummary(
        courseId: event.courseId,
        userId: event.userId,
      );

      emit(CourseProgressSummaryLoaded(summary: summary));
      print('UserProgressBloc: Loaded progress summary for user ${event.userId ?? 'current'}, course ${event.courseId}');
    } catch (e) {
      emit(UserProgressError(
        error: 'Failed to get course progress summary: $e',
        courseId: event.courseId,
      ));
      print('UserProgressBloc: Error getting course progress summary: $e');
    }
  }

  Future<void> _onResetUserProgressState(
    ResetUserProgressState event,
    Emitter<UserProgressState> emit,
  ) async {
    emit(const UserProgressInitial());
    print('UserProgressBloc: Reset user progress state');
  }
}
