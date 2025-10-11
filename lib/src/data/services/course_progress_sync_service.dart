import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/user_progress_repository.dart';

class CourseProgressSyncService {
  final UserProgressRepository _userProgressRepository;
  final FirebaseAuth _auth;

  CourseProgressSyncService({
    required UserProgressRepository userProgressRepository,
    required FirebaseAuth auth,
  }) : _userProgressRepository = userProgressRepository,
        _auth = auth;

  /// Sync user progress for all users when course structure changes
  Future<void> syncCourseProgressForAllUsers(String courseId) async {
    try {
      print('CourseProgressSyncService: Starting sync for course: $courseId');
      await _userProgressRepository.syncCourseStructureForAllUsers(courseId);
      print('CourseProgressSyncService: Completed sync for course: $courseId');
    } catch (e) {
      print('CourseProgressSyncService: Error syncing course progress: $e');
      // Don't throw error as this is supplementary functionality
    }
  }

  /// Sync user progress for current user when course structure changes
  Future<void> syncCourseProgressForCurrentUser(String courseId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('CourseProgressSyncService: No current user, skipping sync');
        return;
      }

      print('CourseProgressSyncService: Starting sync for current user: ${currentUser.uid}');
      await _userProgressRepository.autoSyncCourseStructure(
        courseId: courseId,
        userId: currentUser.uid,
      );
      print('CourseProgressSyncService: Completed sync for current user: ${currentUser.uid}');
    } catch (e) {
      print('CourseProgressSyncService: Error syncing current user progress: $e');
      // Don't throw error as this is supplementary functionality
    }
  }
}
