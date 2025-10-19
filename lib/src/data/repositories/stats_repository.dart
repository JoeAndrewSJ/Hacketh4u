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

  /// Get all users with their basic stats (with pagination)
  Future<List<UserStats>> getAllUsersStats({int limit = 50, DocumentSnapshot? startAfter}) async {
    try {
      print('StatsRepository: Fetching users stats (limit: $limit)...');

      // Build query with pagination
      Query query = _firestore.collection('users').orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final usersSnapshot = await query.get();
      final List<UserStats> usersStats = [];

      // Fetch payment data for all users in batch
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      // Get payments for these users
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', whereIn: userIds.take(10).toList()) // Firestore limit for whereIn
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      // Group payments by userId
      final Map<String, double> userSpending = {};
      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final userId = paymentData['userId'] as String?;
        if (userId == null) continue;

        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        for (final course in courses) {
          final spending = userSpending[userId] ?? 0.0;
          userSpending[userId] = spending + (course['price'] ?? 0.0).toDouble();
        }
      }

      // Get progress data for these users
      final progressSnapshot = await _firestore
          .collection('user_progress')
          .where('userId', whereIn: userIds.take(10).toList())
          .get();

      // Group progress by userId
      final Map<String, Map<String, dynamic>> userProgress = {};
      for (final progressDoc in progressSnapshot.docs) {
        final progressData = progressDoc.data();
        final userId = progressData['userId'] as String?;
        if (userId == null) continue;

        if (!userProgress.containsKey(userId)) {
          userProgress[userId] = {
            'enrolled': 0,
            'completed': 0,
            'totalProgress': 0.0,
          };
        }

        userProgress[userId]!['enrolled'] = (userProgress[userId]!['enrolled'] as int) + 1;

        final isCompleted = progressData['isCourseCompleted'] ?? false;
        if (isCompleted) {
          userProgress[userId]!['completed'] = (userProgress[userId]!['completed'] as int) + 1;
        }

        final progress = (progressData['overallCompletionPercentage'] ?? 0.0).toDouble();
        userProgress[userId]!['totalProgress'] =
            (userProgress[userId]!['totalProgress'] as double) + progress;
      }

      // Build UserStats for each user
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;
        final userName = userData['name'] ?? userData['displayName'] ?? 'Unknown User';
        final userEmail = userData['email'] ?? 'No email';

        final enrolled = userProgress[userId]?['enrolled'] ?? 0;
        final completed = userProgress[userId]?['completed'] ?? 0;
        final totalProgress = userProgress[userId]?['totalProgress'] ?? 0.0;
        final averageProgress = enrolled > 0 ? (totalProgress as double) / enrolled : 0.0;
        final lastActivity = (userData['lastLoginAt'] as Timestamp?)?.toDate() ??
                            (userData['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now();

        usersStats.add(UserStats(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          coursesEnrolled: enrolled,
          coursesCompleted: completed,
          totalSpent: userSpending[userId] ?? 0.0,
          averageProgress: averageProgress,
          lastActivity: lastActivity,
        ));
      }

      // Sort by total spent (descending)
      usersStats.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      print('StatsRepository: Retrieved ${usersStats.length} users stats');
      return usersStats;
    } catch (e) {
      print('StatsRepository: Error fetching users stats: $e');
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
    try {
      // Optimized: Only fetch users who have made payments
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('paymentStatus', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to recent 50 payments for better performance
          .get();

      // Group by userId and calculate total spent
      final Map<String, double> userSpending = {};
      final Map<String, Map<String, dynamic>> userInfo = {};

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final userId = paymentData['userId'] as String?;
        if (userId == null) continue;

        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        double paymentTotal = 0.0;
        for (final course in courses) {
          paymentTotal += (course['price'] ?? 0.0).toDouble();
        }

        userSpending[userId] = (userSpending[userId] ?? 0.0) + paymentTotal;

        if (!userInfo.containsKey(userId)) {
          userInfo[userId] = {
            'name': paymentData['userName'] ?? 'Unknown User',
            'email': paymentData['userEmail'] ?? 'No email',
          };
        }
      }

      // Sort users by spending and take top 10
      final sortedUsers = userSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topUserIds = sortedUsers.take(10).map((e) => e.key).toList();

      // Fetch course enrollment data only for top users
      final List<UserStats> topUsers = [];
      for (final userId in topUserIds) {
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
        final info = userInfo[userId] ?? {'name': 'Unknown', 'email': 'No email'};

        topUsers.add(UserStats(
          userId: userId,
          userName: info['name'] as String,
          userEmail: info['email'] as String,
          coursesEnrolled: coursesEnrolled,
          coursesCompleted: coursesCompleted,
          totalSpent: userSpending[userId] ?? 0.0,
          averageProgress: averageProgress,
          lastActivity: DateTime.now(),
        ));
      }

      return topUsers;
    } catch (e) {
      print('StatsRepository: Error fetching top users: $e');
      return [];
    }
  }

  Future<List<CourseStats>> _getTopCourses() async {
    try {
      // Optimized: Fetch revenue data from payments first
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('paymentStatus', isEqualTo: 'completed')
          .limit(100) // Limit payments for better performance
          .get();

      // Calculate revenue per course
      final Map<String, double> courseRevenue = {};
      final Map<String, String> courseTitles = {};

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final courses = paymentData['courses'] as List<dynamic>? ?? [];

        for (final course in courses) {
          final courseId = course['courseId'] as String?;
          if (courseId == null) continue;

          final price = (course['price'] ?? 0.0).toDouble();
          final title = course['courseName'] ?? course['courseTitle'] ?? 'Unknown Course';

          courseRevenue[courseId] = (courseRevenue[courseId] ?? 0.0) + price;
          courseTitles[courseId] = title;
        }
      }

      // Sort by revenue and take top 10
      final sortedCourses = courseRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCourseIds = sortedCourses.take(10).map((e) => e.key).toList();

      // Fetch detailed stats only for top 10 courses
      final List<CourseStats> courseStats = [];

      for (final courseId in topCourseIds) {
        // Get course details
        final courseDoc = await _firestore.collection('courses').doc(courseId).get();
        final courseData = courseDoc.exists ? courseDoc.data() : null;
        final courseTitle = courseData?['title'] ?? courseTitles[courseId] ?? 'Unknown Course';
        final averageRating = (courseData?['rating'] ?? 0.0).toDouble();

        // Get enrollments and completions
        final enrollmentsSnapshot = await _firestore
            .collection('user_progress')
            .where('courseId', isEqualTo: courseId)
            .limit(100) // Limit for performance
            .get();

        final enrollments = enrollmentsSnapshot.docs.length;
        int completions = 0;

        for (final progressDoc in enrollmentsSnapshot.docs) {
          final progressData = progressDoc.data();
          final isCompleted = progressData['isCourseCompleted'] ?? false;
          if (isCompleted) completions++;
        }

        final completionRate = enrollments > 0 ? (completions / enrollments) * 100 : 0.0;

        courseStats.add(CourseStats(
          courseId: courseId,
          courseTitle: courseTitle,
          enrollments: enrollments,
          completions: completions,
          averageRating: averageRating,
          revenue: courseRevenue[courseId] ?? 0.0,
          completionRate: completionRate,
        ));
      }

      return courseStats;
    } catch (e) {
      print('StatsRepository: Error fetching top courses: $e');
      return [];
    }
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
