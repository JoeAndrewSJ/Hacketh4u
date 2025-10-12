import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stats_model.dart';

class StatsRepository {
  final FirebaseFirestore _firestore;

  StatsRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// Get comprehensive app statistics
  Future<AppStats> getAppStats() async {
    try {
      print('StatsRepository: Fetching app statistics...');

      // Get basic counts
      final totalUsers = await _getTotalUsers();
      final totalCourses = await _getTotalCourses();
      final totalPayments = await _getTotalPayments();
      
      // Get payment statistics
      final paidUsers = await _getPaidUsersCount();
      final unpaidUsers = totalUsers - paidUsers;
      final totalRevenue = await _getTotalRevenue();
      
      // Get detailed statistics
      final courseEnrollments = await _getCourseEnrollments();
      final monthlyRevenue = await _getMonthlyRevenue();
      final topUsers = await _getTopUsers();
      final topCourses = await _getTopCourses();

      final stats = AppStats(
        totalUsers: totalUsers,
        totalCourses: totalCourses,
        totalPayments: totalPayments,
        paidUsers: paidUsers,
        unpaidUsers: unpaidUsers,
        totalRevenue: totalRevenue,
        courseEnrollments: courseEnrollments,
        monthlyRevenue: monthlyRevenue,
        topUsers: topUsers,
        topCourses: topCourses,
      );

      print('StatsRepository: Retrieved stats - Users: $totalUsers, Courses: $totalCourses, Revenue: $totalRevenue');
      return stats;
    } catch (e) {
      print('StatsRepository: Error fetching app stats: $e');
      throw Exception('Failed to fetch app statistics: $e');
    }
  }

  /// Get detailed user progress for a specific user
  Future<UserProgressDetail> getUserProgressDetail(String userId) async {
    try {
      print('StatsRepository: Fetching user progress detail for: $userId');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? userData['displayName'] ?? 'Unknown User';
      final userEmail = userData['email'] ?? 'No email';

      // Get user progress
      final progressSnapshot = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .get();

      final courseProgresses = <CourseProgressDetail>[];
      double totalProgress = 0.0;
      int completedCourses = 0;

      for (final doc in progressSnapshot.docs) {
        final progressData = doc.data();
        final progressPercentage = (progressData['overallCompletionPercentage'] ?? 0.0).toDouble();
        final isCompleted = progressData['isCourseCompleted'] ?? false;
        
        totalProgress += progressPercentage;
        if (isCompleted) completedCourses++;

        courseProgresses.add(CourseProgressDetail(
          courseId: progressData['courseId'] ?? '',
          courseTitle: progressData['courseTitle'] ?? 'Unknown Course',
          progressPercentage: progressPercentage,
          totalVideos: _calculateTotalVideos(progressData['moduleProgresses'] ?? {}),
          completedVideos: _calculateCompletedVideos(progressData['moduleProgresses'] ?? {}),
          isCompleted: isCompleted,
          isCertificateEligible: progressData['isCertificateEligible'] ?? false,
          lastWatchedAt: (progressData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }

      final overallProgress = courseProgresses.isNotEmpty ? totalProgress / courseProgresses.length : 0.0;

      final userProgressDetail = UserProgressDetail(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        courseProgresses: courseProgresses,
        overallProgress: overallProgress,
        totalCourses: courseProgresses.length,
        completedCourses: completedCourses,
      );

      print('StatsRepository: Retrieved user progress - Courses: ${courseProgresses.length}, Overall: ${overallProgress.toStringAsFixed(1)}%');
      return userProgressDetail;
    } catch (e) {
      print('StatsRepository: Error fetching user progress detail: $e');
      throw Exception('Failed to fetch user progress detail: $e');
    }
  }

  /// Get all users with their basic stats
  Future<List<UserStats>> getAllUsersStats() async {
    try {
      print('StatsRepository: Fetching all users stats...');

      final usersSnapshot = await _firestore.collection('users').get();
      final List<UserStats> usersStats = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final userName = userData['name'] ?? userData['displayName'] ?? 'Unknown User';
        final userEmail = userData['email'] ?? 'No email';

        // Get user's payment data
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .where('paymentStatus', isEqualTo: 'completed')
            .get();

        double totalSpent = 0.0;
        for (final paymentDoc in paymentsSnapshot.docs) {
          final paymentData = paymentDoc.data();
          final courses = paymentData['courses'] as List<dynamic>? ?? [];
          for (final course in courses) {
            totalSpent += (course['price'] ?? 0.0).toDouble();
          }
        }

        // Get user's progress data
        final progressSnapshot = await _firestore
            .collection('user_progress')
            .where('userId', isEqualTo: userId)
            .get();

        int coursesEnrolled = progressSnapshot.docs.length;
        int coursesCompleted = 0;
        double totalProgress = 0.0;

        for (final progressDoc in progressSnapshot.docs) {
          final progressData = progressDoc.data();
          final progressPercentage = (progressData['overallCompletionPercentage'] ?? 0.0).toDouble();
          final isCompleted = progressData['isCourseCompleted'] ?? false;
          
          totalProgress += progressPercentage;
          if (isCompleted) coursesCompleted++;
        }

        final averageProgress = coursesEnrolled > 0 ? totalProgress / coursesEnrolled : 0.0;
        final lastActivity = (userData['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        usersStats.add(UserStats(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          coursesEnrolled: coursesEnrolled,
          coursesCompleted: coursesCompleted,
          totalSpent: totalSpent,
          averageProgress: averageProgress,
          lastActivity: lastActivity,
        ));
      }

      // Sort by total spent (descending)
      usersStats.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      print('StatsRepository: Retrieved ${usersStats.length} users stats');
      return usersStats;
    } catch (e) {
      print('StatsRepository: Error fetching all users stats: $e');
      throw Exception('Failed to fetch users stats: $e');
    }
  }

  /// Private helper methods
  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalCourses() async {
    final snapshot = await _firestore.collection('courses').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalPayments() async {
    final snapshot = await _firestore.collection('payments').get();
    return snapshot.docs.length;
  }

  Future<int> _getPaidUsersCount() async {
    final snapshot = await _firestore
        .collection('payments')
        .where('paymentStatus', isEqualTo: 'completed')
        .get();
    
    final userIds = <String>{};
    for (final doc in snapshot.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId != null) {
        userIds.add(userId);
      }
    }
    
    return userIds.length;
  }

  Future<double> _getTotalRevenue() async {
    final snapshot = await _firestore
        .collection('payments')
        .where('paymentStatus', isEqualTo: 'completed')
        .get();

    double totalRevenue = 0.0;
    for (final doc in snapshot.docs) {
      final paymentData = doc.data();
      final courses = paymentData['courses'] as List<dynamic>? ?? [];
      for (final course in courses) {
        totalRevenue += (course['price'] ?? 0.0).toDouble();
      }
    }

    return totalRevenue;
  }

  Future<Map<String, int>> _getCourseEnrollments() async {
    final snapshot = await _firestore.collection('user_progress').get();
    final enrollments = <String, int>{};

    for (final doc in snapshot.docs) {
      final courseId = doc.data()['courseId'] as String?;
      if (courseId != null) {
        enrollments[courseId] = (enrollments[courseId] ?? 0) + 1;
      }
    }

    return enrollments;
  }

  Future<Map<String, double>> _getMonthlyRevenue() async {
    final snapshot = await _firestore
        .collection('payments')
        .where('paymentStatus', isEqualTo: 'completed')
        .get();

    final monthlyRevenue = <String, double>{};

    for (final doc in snapshot.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
      
      final courses = doc.data()['courses'] as List<dynamic>? ?? [];
      double monthRevenue = 0.0;
      for (final course in courses) {
        monthRevenue += (course['price'] ?? 0.0).toDouble();
      }
      
      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + monthRevenue;
    }

    return monthlyRevenue;
  }

  Future<List<UserStats>> _getTopUsers() async {
    final allUsers = await getAllUsersStats();
    return allUsers.take(10).toList();
  }

  Future<List<CourseStats>> _getTopCourses() async {
    final coursesSnapshot = await _firestore.collection('courses').get();
    final List<CourseStats> courseStats = [];

    for (final courseDoc in coursesSnapshot.docs) {
      final courseData = courseDoc.data();
      final courseId = courseDoc.id;
      final courseTitle = courseData['title'] ?? 'Unknown Course';
      final averageRating = (courseData['rating'] ?? 0.0).toDouble();

      // Get enrollments
      final enrollmentsSnapshot = await _firestore
          .collection('user_progress')
          .where('courseId', isEqualTo: courseId)
          .get();

      final enrollments = enrollmentsSnapshot.docs.length;
      
      // Get completions
      int completions = 0;
      for (final progressDoc in enrollmentsSnapshot.docs) {
        final progressData = progressDoc.data();
        final isCompleted = progressData['isCourseCompleted'] ?? false;
        if (isCompleted) completions++;
      }

      // Get revenue
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      double revenue = 0.0;
      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        for (final course in courses) {
          if (course['courseId'] == courseId) {
            revenue += (course['price'] ?? 0.0).toDouble();
          }
        }
      }

      final completionRate = enrollments > 0 ? (completions / enrollments) * 100 : 0.0;

      courseStats.add(CourseStats(
        courseId: courseId,
        courseTitle: courseTitle,
        enrollments: enrollments,
        completions: completions,
        averageRating: averageRating,
        revenue: revenue,
        completionRate: completionRate,
      ));
    }

    // Sort by revenue (descending)
    courseStats.sort((a, b) => b.revenue.compareTo(a.revenue));
    return courseStats.take(10).toList();
  }

  int _calculateTotalVideos(Map<String, dynamic> moduleProgresses) {
    int totalVideos = 0;
    for (final moduleProgress in moduleProgresses.values) {
      final videoProgresses = moduleProgress['videoProgresses'] as Map<String, dynamic>? ?? {};
      totalVideos += videoProgresses.length;
    }
    return totalVideos;
  }

  int _calculateCompletedVideos(Map<String, dynamic> moduleProgresses) {
    int completedVideos = 0;
    for (final moduleProgress in moduleProgresses.values) {
      final videoProgresses = moduleProgress['videoProgresses'] as Map<String, dynamic>? ?? {};
      for (final videoProgress in videoProgresses.values) {
        final isCompleted = videoProgress['isCompleted'] ?? false;
        if (isCompleted) completedVideos++;
      }
    }
    return completedVideos;
  }
}
