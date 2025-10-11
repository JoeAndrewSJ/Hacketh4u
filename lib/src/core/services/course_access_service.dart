import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class CourseAccessService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CourseAccessService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, _auth = auth;

  /// Check if user has purchased and has access to a course
  Future<bool> hasCourseAccess(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('CourseAccessService: User not authenticated');
        return false;
      }

      print('CourseAccessService: Checking access for course: $courseId, user: ${user.uid}');

      // Check if user has any completed payment for this course
      final paymentQuery = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      print('CourseAccessService: Found ${paymentQuery.docs.length} completed payments');

      for (var paymentDoc in paymentQuery.docs) {
        final paymentData = paymentDoc.data();
        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        
        print('CourseAccessService: Checking payment ${paymentDoc.id} with ${courses.length} courses');
        
        for (var course in courses) {
          final courseMap = course as Map<String, dynamic>;
          final purchasedCourseId = courseMap['courseId'] as String?;
          final accessEndDate = courseMap['accessEndDate'] as Timestamp?;
          
          print('CourseAccessService: Course ID: $purchasedCourseId, Access End: $accessEndDate');
          
          if (purchasedCourseId == courseId) {
            // Check if access is still valid
            if (accessEndDate != null) {
              final now = DateTime.now();
              final endDate = accessEndDate.toDate();
              
              print('CourseAccessService: Current time: $now, Access ends: $endDate');
              
              if (now.isBefore(endDate)) {
                print('CourseAccessService: User has valid access to course $courseId');
                return true;
              } else {
                print('CourseAccessService: User access to course $courseId has expired');
              }
            } else {
              // No end date means lifetime access
              print('CourseAccessService: User has lifetime access to course $courseId');
              return true;
            }
          }
        }
      }

      print('CourseAccessService: User does not have access to course $courseId');
      return false;
    } catch (e) {
      print('CourseAccessService: Error checking course access: $e');
      return false;
    }
  }

  /// Get all courses that user has purchased and has access to (returns course IDs)
  Future<List<String>> getPurchasedCourses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('CourseAccessService: User not authenticated');
        return [];
      }

      print('CourseAccessService: Getting purchased courses for user: ${user.uid}');

      final paymentQuery = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      final Set<String> purchasedCourses = {};

      for (var paymentDoc in paymentQuery.docs) {
        final paymentData = paymentDoc.data();
        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        
        for (var course in courses) {
          final courseMap = course as Map<String, dynamic>;
          final courseId = courseMap['courseId'] as String?;
          final accessEndDate = courseMap['accessEndDate'] as Timestamp?;
          
          if (courseId != null) {
            // Check if access is still valid
            if (accessEndDate != null) {
              final now = DateTime.now();
              final endDate = accessEndDate.toDate();
              
              if (now.isBefore(endDate)) {
                purchasedCourses.add(courseId);
              }
            } else {
              // No end date means lifetime access
              purchasedCourses.add(courseId);
            }
          }
        }
      }

      print('CourseAccessService: User has access to ${purchasedCourses.length} courses: ${purchasedCourses.toList()}');
      return purchasedCourses.toList();
    } catch (e) {
      print('CourseAccessService: Error getting purchased courses: $e');
      return [];
    }
  }

  /// Get detailed course information for purchased courses
  Future<List<Map<String, dynamic>>> getPurchasedCoursesWithDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('CourseAccessService: User not authenticated');
        return [];
      }

      print('CourseAccessService: Getting purchased courses with details for user: ${user.uid}');

      // First get the purchased course IDs
      final purchasedCourseIds = await getPurchasedCourses();
      print('CourseAccessService: Found ${purchasedCourseIds.length} purchased course IDs: $purchasedCourseIds');
      
      if (purchasedCourseIds.isEmpty) {
        print('CourseAccessService: No purchased courses found, returning empty list');
        return [];
      }

      // Then fetch the course details from the courses collection
      final List<Map<String, dynamic>> purchasedCourses = [];
      
      for (final courseId in purchasedCourseIds) {
        try {
          print('CourseAccessService: Fetching course details for: $courseId');
          final courseDoc = await _firestore
              .collection('courses')
              .doc(courseId)
              .get();
          
          if (courseDoc.exists) {
            final courseData = courseDoc.data()!;
            courseData['id'] = courseId; // Ensure ID is included
            purchasedCourses.add(courseData);
            print('CourseAccessService: Successfully loaded course: ${courseData['title']}');
          } else {
            print('CourseAccessService: Course document does not exist: $courseId');
          }
        } catch (e) {
          print('CourseAccessService: Error fetching course $courseId: $e');
        }
      }

      print('CourseAccessService: Loaded ${purchasedCourses.length} purchased courses with details');
      return purchasedCourses;
    } catch (e) {
      print('CourseAccessService: Error getting purchased courses with details: $e');
      return [];
    }
  }

  /// Check if user has access to a specific video (for premium content)
  Future<bool> hasVideoAccess(String courseId, String? videoId) async {
    try {
      // First check if user has course access
      final hasCourseAccessResult = await hasCourseAccess(courseId);
      
      if (hasCourseAccessResult) {
        print('CourseAccessService: User has access to video $videoId in course $courseId');
        return true;
      }

      // If no course access, check if it's a free video
      if (videoId != null) {
        // This would require checking the video's isPremium flag
        // For now, we'll assume all videos in a course require course purchase
        print('CourseAccessService: User does not have access to video $videoId in course $courseId');
        return false;
      }

      return false;
    } catch (e) {
      print('CourseAccessService: Error checking video access: $e');
      return false;
    }
  }
}
