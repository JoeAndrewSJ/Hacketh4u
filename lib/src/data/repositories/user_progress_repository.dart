import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_progress_model.dart';
import 'course_repository.dart';

class UserProgressRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CourseRepository _courseRepository;

  UserProgressRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required CourseRepository courseRepository,
  }) : _firestore = firestore, 
       _auth = auth,
       _courseRepository = courseRepository;

  // Collection references
  static const String _userProgressCollection = 'user_progress';
  static const String _coursesCollection = 'courses';
  static const String _paymentsCollection = 'payments';

  /// Initialize user progress when they purchase a course
  Future<UserProgressModel> initializeUserProgress({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('UserProgressRepository: Initializing progress for user $uid, course $courseId');

      // Get course data using CourseRepository
      final courseData = await _courseRepository.getCourseById(courseId);
      if (courseData == null) {
        throw Exception('Course not found');
      }

      final courseTitle = courseData['title'] as String;
      final completionPercentage = (courseData['completionPercentage'] as num?)?.toDouble() ?? 80.0;
      final certificateTemplateUrl = courseData['certificateTemplateUrl'] as String?;

      // Get course modules and videos using CourseRepository
      final modules = await _courseRepository.getCourseModules(courseId);

      print('UserProgressRepository: Found ${modules.length} modules for course $courseId');

      // Initialize module progresses
      final moduleProgresses = <String, ModuleProgress>{};
      
      for (final moduleData in modules) {
        final moduleId = moduleData['id'] as String;
        final moduleTitle = moduleData['title'] as String? ?? 'Untitled Module';

        print('UserProgressRepository: Processing module: $moduleTitle ($moduleId)');

        // Get videos for this module using CourseRepository
        final videos = await _courseRepository.getModuleVideos(courseId, moduleId);

        print('UserProgressRepository: Found ${videos.length} videos for module $moduleId');

        // Initialize video progresses
        final videoProgresses = <String, VideoProgress>{};
        
        for (final videoData in videos) {
          final videoId = videoData['id'] as String;
          final videoTitle = videoData['title'] as String? ?? 'Untitled Video';
          final duration = videoData['duration'] as int? ?? 0;

          videoProgresses[videoId] = VideoProgress(
            videoId: videoId,
            videoTitle: videoTitle,
            watchPercentage: 0.0,
            watchedDuration: Duration.zero,
            totalDuration: Duration(seconds: duration),
            lastWatchedAt: DateTime.now(),
            isCompleted: false,
          );
        }

        moduleProgresses[moduleId] = ModuleProgress(
          moduleId: moduleId,
          moduleTitle: moduleTitle,
          videoProgresses: videoProgresses,
          completionPercentage: 0.0,
          isCompleted: false,
        );
      }

      // Create user progress document
      final now = DateTime.now();
      final userProgress = UserProgressModel(
        id: '', // Will be set by Firestore
        userId: uid,
        courseId: courseId,
        courseTitle: courseTitle,
        moduleProgresses: moduleProgresses,
        overallCompletionPercentage: 0.0,
        isCourseCompleted: false,
        isCertificateEligible: false,
        isCertificateDownloaded: false,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_userProgressCollection)
          .add(userProgress.toFirestore());

      final createdProgress = userProgress.copyWith(id: docRef.id);
      
      print('UserProgressRepository: Created progress for user $uid, course $courseId');
      return createdProgress;
    } catch (e) {
      print('UserProgressRepository: Error initializing user progress: $e');
      throw Exception('Failed to initialize user progress: $e');
    }
  }

  /// Update video progress
  Future<void> updateVideoProgress({
    required String courseId,
    required String moduleId,
    required String videoId,
    required double watchPercentage,
    required Duration watchedDuration,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('UserProgressRepository: Updating video progress for user $uid, video $videoId');
      print('UserProgressRepository: Watch percentage: $watchPercentage%, Duration: ${watchedDuration.inSeconds}s');

      // Get user progress document
      final progressQuery = await _firestore
          .collection(_userProgressCollection)
          .where('userId', isEqualTo: uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (progressQuery.docs.isEmpty) {
        throw Exception('User progress not found');
      }

      final progressDoc = progressQuery.docs.first;
      final progressData = UserProgressModel.fromFirestore(progressDoc);
      
      // Update video progress
      print('UserProgressRepository: Available modules: ${progressData.moduleProgresses.keys.toList()}');
      print('UserProgressRepository: Looking for module: $moduleId');
      
      final moduleProgress = progressData.moduleProgresses[moduleId];
      if (moduleProgress == null) {
        print('UserProgressRepository: Module $moduleId not found, available modules: ${progressData.moduleProgresses.keys.toList()}');
        // Try to sync course structure first
        await syncCourseStructure(courseId: courseId, userId: uid);
        
        // Try again after sync
        final updatedProgressQuery = await _firestore
            .collection(_userProgressCollection)
            .where('userId', isEqualTo: uid)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();
            
        if (updatedProgressQuery.docs.isEmpty) {
          throw Exception('User progress not found after sync');
        }
        
        final updatedProgressData = UserProgressModel.fromFirestore(updatedProgressQuery.docs.first);
        final updatedModuleProgress = updatedProgressData.moduleProgresses[moduleId];
        
        if (updatedModuleProgress == null) {
          throw Exception('Module progress not found after sync. Available modules: ${updatedProgressData.moduleProgresses.keys.toList()}');
        }
        
        // Continue with updated progress data
        return _updateVideoProgressInModule(updatedProgressData, updatedModuleProgress, videoId, watchPercentage, watchedDuration);
      }

      return _updateVideoProgressInModule(progressData, moduleProgress, videoId, watchPercentage, watchedDuration);
    } catch (e) {
      print('UserProgressRepository: Error updating video progress: $e');
      throw Exception('Failed to update video progress: $e');
    }
  }

  /// Get user progress for a course
  Future<UserProgressModel?> getUserProgress({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final progressQuery = await _firestore
          .collection(_userProgressCollection)
          .where('userId', isEqualTo: uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (progressQuery.docs.isEmpty) {
        return null;
      }

      return UserProgressModel.fromFirestore(progressQuery.docs.first);
    } catch (e) {
      print('UserProgressRepository: Error getting user progress: $e');
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Get all user progress
  Future<List<UserProgressModel>> getAllUserProgress({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final progressQuery = await _firestore
          .collection(_userProgressCollection)
          .where('userId', isEqualTo: uid)
          .orderBy('updatedAt', descending: true)
          .get();

      return progressQuery.docs
          .map((doc) => UserProgressModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('UserProgressRepository: Error getting all user progress: $e');
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Mark certificate as downloaded
  Future<void> markCertificateDownloaded({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final progressQuery = await _firestore
          .collection(_userProgressCollection)
          .where('userId', isEqualTo: uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (progressQuery.docs.isEmpty) {
        throw Exception('User progress not found');
      }

      final progressDoc = progressQuery.docs.first;
      await _firestore.collection(_userProgressCollection).doc(progressDoc.id).update({
        'isCertificateDownloaded': true,
        'certificateDownloadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('UserProgressRepository: Marked certificate as downloaded for user $uid, course $courseId');
    } catch (e) {
      print('UserProgressRepository: Error marking certificate as downloaded: $e');
      throw Exception('Failed to mark certificate as downloaded: $e');
    }
  }

  /// Sync course modules and videos with progress (when modules/videos are added/deleted)
  Future<void> syncCourseStructure({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('UserProgressRepository: Syncing course structure for user $uid, course $courseId');

      // Get user progress
      final userProgress = await getUserProgress(courseId: courseId, userId: uid);
      if (userProgress == null) {
        print('UserProgressRepository: No progress found, skipping sync');
        return;
      }

      // Get current course structure using CourseRepository
      final modules = await _courseRepository.getCourseModules(courseId);

      print('UserProgressRepository: Syncing - Found ${modules.length} modules for course $courseId');

      final updatedModuleProgresses = <String, ModuleProgress>{};

      for (final moduleData in modules) {
        final moduleId = moduleData['id'] as String;
        final moduleTitle = moduleData['title'] as String? ?? 'Untitled Module';

        print('UserProgressRepository: Syncing - Processing module: $moduleTitle ($moduleId)');

        // Get videos for this module using CourseRepository
        final videos = await _courseRepository.getModuleVideos(courseId, moduleId);

        print('UserProgressRepository: Syncing - Found ${videos.length} videos for module $moduleId');

        // Get existing module progress or create new
        final existingModuleProgress = userProgress.moduleProgresses[moduleId];
        final updatedVideoProgresses = <String, VideoProgress>{};

        if (existingModuleProgress == null) {
          print('UserProgressRepository: Syncing - Added new module: $moduleTitle ($moduleId)');
        } else {
          print('UserProgressRepository: Syncing - Updating existing module: $moduleTitle ($moduleId)');
        }

        for (final videoData in videos) {
          final videoId = videoData['id'] as String;
          final videoTitle = videoData['title'] as String? ?? 'Untitled Video';
          final duration = videoData['duration'] as int? ?? 0;

          // Get existing video progress or create new
          final existingVideoProgress = existingModuleProgress?.videoProgresses[videoId];
          
          if (existingVideoProgress != null) {
            // Keep existing progress but update metadata if changed
            updatedVideoProgresses[videoId] = existingVideoProgress.copyWith(
              videoTitle: videoTitle,
              totalDuration: Duration(seconds: duration),
            );
            print('UserProgressRepository: Syncing - Updated existing video: $videoTitle ($videoId)');
          } else {
            // Create new video progress for newly added video
            updatedVideoProgresses[videoId] = VideoProgress(
              videoId: videoId,
              videoTitle: videoTitle,
              watchPercentage: 0.0,
              watchedDuration: Duration.zero,
              totalDuration: Duration(seconds: duration),
              lastWatchedAt: DateTime.now(), // Use current time as default
              isCompleted: false,
            );
            print('UserProgressRepository: Syncing - Added new video: $videoTitle ($videoId)');
          }
        }

        // Calculate module completion percentage
        final moduleCompletionPercentage = _calculateModuleCompletionPercentage(updatedVideoProgresses);

        updatedModuleProgresses[moduleId] = ModuleProgress(
          moduleId: moduleId,
          moduleTitle: moduleTitle,
          videoProgresses: updatedVideoProgresses,
          completionPercentage: moduleCompletionPercentage,
          isCompleted: moduleCompletionPercentage >= 90.0,
        );
      }

      // Calculate overall completion percentage
      final overallCompletionPercentage = _calculateOverallCompletionPercentage(updatedModuleProgresses);

      // Get course completion percentage requirement
      final courseDoc = await _firestore.collection(_coursesCollection).doc(courseId).get();
      final courseData = courseDoc.data()!;
      final requiredCompletionPercentage = (courseData['completionPercentage'] as num?)?.toDouble() ?? 80.0;

      // Update user progress
      final updatedProgress = userProgress.copyWith(
        moduleProgresses: updatedModuleProgresses,
        overallCompletionPercentage: overallCompletionPercentage,
        isCourseCompleted: overallCompletionPercentage >= requiredCompletionPercentage,
        isCertificateEligible: overallCompletionPercentage >= requiredCompletionPercentage,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      final progressQuery = await _firestore
          .collection(_userProgressCollection)
          .where('userId', isEqualTo: uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (progressQuery.docs.isNotEmpty) {
        await _firestore
            .collection(_userProgressCollection)
            .doc(progressQuery.docs.first.id)
            .update(updatedProgress.toFirestore());
      }

      print('UserProgressRepository: Synced course structure for user $uid, course $courseId');
    } catch (e) {
      print('UserProgressRepository: Error syncing course structure: $e');
      throw Exception('Failed to sync course structure: $e');
    }
  }

  /// Helper method to update video progress within a module
  Future<void> _updateVideoProgressInModule(
    UserProgressModel progressData,
    ModuleProgress moduleProgress,
    String videoId,
    double watchPercentage,
    Duration watchedDuration,
  ) async {
    final videoProgress = moduleProgress.videoProgresses[videoId];
    if (videoProgress == null) {
      throw Exception('Video progress not found for video $videoId');
    }

    // EDGE CASE 1: Skip update if video is already completed (100%)
    if (videoProgress.isCompleted && videoProgress.watchPercentage >= 100.0) {
      print('UserProgressRepository: Video $videoId already completed at 100%, skipping update');
      return;
    }

    // EDGE CASE 2: Skip update if new percentage is less than current (prevent backward progress)
    if (watchPercentage < videoProgress.watchPercentage && videoProgress.watchPercentage >= 90.0) {
      print('UserProgressRepository: Preventing backward progress for video $videoId (${videoProgress.watchPercentage}% -> $watchPercentage%)');
      return;
    }

    // EDGE CASE 3: Skip update if percentage hasn't changed significantly (< 1%)
    if ((watchPercentage - videoProgress.watchPercentage).abs() < 1.0 && watchPercentage < 90.0) {
      print('UserProgressRepository: Insignificant change for video $videoId (${videoProgress.watchPercentage}% -> $watchPercentage%), skipping update');
      return;
    }

    // EDGE CASE 4: Once video reaches 100%, lock it at 100%
    final finalPercentage = watchPercentage >= 100.0 ? 100.0 : watchPercentage;
    final isNowCompleted = finalPercentage >= 90.0;

    final updatedVideoProgress = videoProgress.copyWith(
      watchPercentage: finalPercentage,
      watchedDuration: watchedDuration,
      lastWatchedAt: DateTime.now(),
      isCompleted: isNowCompleted,
    );

    // Update module progress
    final updatedVideoProgresses = Map<String, VideoProgress>.from(moduleProgress.videoProgresses);
    updatedVideoProgresses[videoId] = updatedVideoProgress;

    // Calculate module completion percentage
    final moduleCompletionPercentage = _calculateModuleCompletionPercentage(updatedVideoProgresses);

    final updatedModuleProgress = moduleProgress.copyWith(
      videoProgresses: updatedVideoProgresses,
      completionPercentage: moduleCompletionPercentage,
      isCompleted: moduleCompletionPercentage >= 90.0,
    );

    // Update overall progress
    final updatedModuleProgresses = Map<String, ModuleProgress>.from(progressData.moduleProgresses);
    updatedModuleProgresses[moduleProgress.moduleId] = updatedModuleProgress;

    final overallCompletionPercentage = _calculateOverallCompletionPercentage(updatedModuleProgresses);

    // Get course completion percentage requirement
    final courseDoc = await _firestore.collection(_coursesCollection).doc(progressData.courseId).get();
    final courseData = courseDoc.data()!;
    final requiredCompletionPercentage = (courseData['completionPercentage'] as num?)?.toDouble() ?? 80.0;

    final updatedProgress = progressData.copyWith(
      moduleProgresses: updatedModuleProgresses,
      overallCompletionPercentage: overallCompletionPercentage,
      isCourseCompleted: overallCompletionPercentage >= requiredCompletionPercentage,
      isCertificateEligible: overallCompletionPercentage >= requiredCompletionPercentage,
      updatedAt: DateTime.now(),
    );

    // Update in Firestore
    final progressQuery = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: progressData.userId)
        .where('courseId', isEqualTo: progressData.courseId)
        .limit(1)
        .get();

    if (progressQuery.docs.isNotEmpty) {
      await _firestore
          .collection(_userProgressCollection)
          .doc(progressQuery.docs.first.id)
          .update(updatedProgress.toFirestore());

      print('UserProgressRepository: Updated video progress - Module: $moduleCompletionPercentage%, Overall: $overallCompletionPercentage%');
    }
  }

  /// Calculate module completion percentage
  double _calculateModuleCompletionPercentage(Map<String, VideoProgress> videoProgresses) {
    if (videoProgresses.isEmpty) return 0.0;

    double totalPercentage = 0.0;
    for (final videoProgress in videoProgresses.values) {
      totalPercentage += videoProgress.watchPercentage;
    }

    return totalPercentage / videoProgresses.length;
  }

  /// Calculate overall course completion percentage
  double _calculateOverallCompletionPercentage(Map<String, ModuleProgress> moduleProgresses) {
    if (moduleProgresses.isEmpty) return 0.0;

    double totalPercentage = 0.0;
    for (final moduleProgress in moduleProgresses.values) {
      totalPercentage += moduleProgress.completionPercentage;
    }

    return totalPercentage / moduleProgresses.length;
  }

  /// Get course progress summary for certificate eligibility
  Future<CourseProgressSummary> getCourseProgressSummary({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final userProgress = await getUserProgress(courseId: courseId, userId: uid);
      if (userProgress == null) {
        throw Exception('User progress not found');
      }

      // Get course data for certificate URL
      final courseDoc = await _firestore.collection(_coursesCollection).doc(courseId).get();
      final courseData = courseDoc.data()!;
      final certificateTemplateUrl = courseData['certificateTemplateUrl'] as String?;

      // Calculate total and completed videos
      int totalVideos = 0;
      int completedVideos = 0;

      for (final moduleProgress in userProgress.moduleProgresses.values) {
        for (final videoProgress in moduleProgress.videoProgresses.values) {
          totalVideos++;
          if (videoProgress.isCompleted) {
            completedVideos++;
          }
        }
      }

      return CourseProgressSummary(
        courseId: courseId,
        courseTitle: userProgress.courseTitle,
        totalVideos: totalVideos,
        completedVideos: completedVideos,
        averageCompletionPercentage: userProgress.overallCompletionPercentage,
        isCertificateEligible: userProgress.isCertificateEligible,
        isCertificateDownloaded: userProgress.isCertificateDownloaded,
        certificateTemplateUrl: certificateTemplateUrl,
      );
    } catch (e) {
      print('UserProgressRepository: Error getting course progress summary: $e');
      throw Exception('Failed to get course progress summary: $e');
    }
  }

  /// Automatically sync course structure when videos are added/updated/deleted
  /// This method should be called from CourseRepository when videos are modified
  Future<void> autoSyncCourseStructure({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        print('UserProgressRepository: Auto-sync skipped - user not authenticated');
        return;
      }

      // Check if user has progress for this course
      final userProgress = await getUserProgress(courseId: courseId, userId: uid);
      if (userProgress == null) {
        print('UserProgressRepository: Auto-sync skipped - no progress found for user $uid, course $courseId');
        return;
      }

      print('UserProgressRepository: Auto-syncing course structure for user $uid, course $courseId');
      await syncCourseStructure(courseId: courseId, userId: uid);
    } catch (e) {
      print('UserProgressRepository: Error in auto-sync: $e');
      // Don't throw exception for auto-sync failures
    }
  }

  /// Get all users who have progress for a specific course (for admin purposes)
  Future<List<String>> getUsersWithProgressForCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_userProgressCollection)
          .where('courseId', isEqualTo: courseId)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      print('UserProgressRepository: Error getting users with progress: $e');
      throw Exception('Failed to get users with progress: $e');
    }
  }

  /// Sync course structure for all users who have progress (admin utility)
  Future<void> syncCourseStructureForAllUsers(String courseId) async {
    try {
      final userIds = await getUsersWithProgressForCourse(courseId);
      print('UserProgressRepository: Syncing course structure for ${userIds.length} users');
      
      for (final userId in userIds) {
        await autoSyncCourseStructure(courseId: courseId, userId: userId);
      }
      
      print('UserProgressRepository: Completed syncing for all users');
    } catch (e) {
      print('UserProgressRepository: Error syncing for all users: $e');
      throw Exception('Failed to sync for all users: $e');
    }
  }
}
