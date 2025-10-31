import 'package:cloud_firestore/cloud_firestore.dart';

class AppStats {
  final int totalUsers;
  final int totalCourses;
  final int totalPayments;
  final int paidUsers;
  final int unpaidUsers;
  final double totalRevenue;
  final Map<String, int> courseEnrollments;
  final Map<String, double> monthlyRevenue;
  final List<UserStats> topUsers;
  final List<CourseStats> topCourses;

  AppStats({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalPayments,
    required this.paidUsers,
    required this.unpaidUsers,
    required this.totalRevenue,
    required this.courseEnrollments,
    required this.monthlyRevenue,
    required this.topUsers,
    required this.topCourses,
  });

  factory AppStats.fromMap(Map<String, dynamic> data) {
    return AppStats(
      totalUsers: data['totalUsers'] ?? 0,
      totalCourses: data['totalCourses'] ?? 0,
      totalPayments: data['totalPayments'] ?? 0,
      paidUsers: data['paidUsers'] ?? 0,
      unpaidUsers: data['unpaidUsers'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      courseEnrollments: Map<String, int>.from(data['courseEnrollments'] ?? {}),
      monthlyRevenue: Map<String, double>.from(data['monthlyRevenue'] ?? {}),
      topUsers: (data['topUsers'] as List<dynamic>?)
          ?.map((e) => UserStats.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      topCourses: (data['topCourses'] as List<dynamic>?)
          ?.map((e) => CourseStats.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'totalCourses': totalCourses,
      'totalPayments': totalPayments,
      'paidUsers': paidUsers,
      'unpaidUsers': unpaidUsers,
      'totalRevenue': totalRevenue,
      'courseEnrollments': courseEnrollments,
      'monthlyRevenue': monthlyRevenue,
      'topUsers': topUsers.map((e) => e.toMap()).toList(),
      'topCourses': topCourses.map((e) => e.toMap()).toList(),
    };
  }
}

class UserStats {
  final String userId;
  final String userName;
  final String userEmail;
  final int coursesEnrolled;
  final int coursesCompleted;
  final double totalSpent;
  final double averageProgress;
  final DateTime lastActivity;

  UserStats({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.coursesEnrolled,
    required this.coursesCompleted,
    required this.totalSpent,
    required this.averageProgress,
    required this.lastActivity,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      coursesEnrolled: data['coursesEnrolled'] ?? 0,
      coursesCompleted: data['coursesCompleted'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      averageProgress: (data['averageProgress'] ?? 0.0).toDouble(),
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'coursesEnrolled': coursesEnrolled,
      'coursesCompleted': coursesCompleted,
      'totalSpent': totalSpent,
      'averageProgress': averageProgress,
      'lastActivity': Timestamp.fromDate(lastActivity),
    };
  }
}

class CourseStats {
  final String courseId;
  final String courseTitle;
  final int enrollments;
  final int completions;
  final double averageRating;
  final double revenue;
  final double completionRate;

  CourseStats({
    required this.courseId,
    required this.courseTitle,
    required this.enrollments,
    required this.completions,
    required this.averageRating,
    required this.revenue,
    required this.completionRate,
  });

  factory CourseStats.fromMap(Map<String, dynamic> data) {
    return CourseStats(
      courseId: data['courseId'] ?? '',
      courseTitle: data['courseTitle'] ?? '',
      enrollments: data['enrollments'] ?? 0,
      completions: data['completions'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'enrollments': enrollments,
      'completions': completions,
      'averageRating': averageRating,
      'revenue': revenue,
      'completionRate': completionRate,
    };
  }
}

class UserProgressDetail {
  final String userId;
  final String userName;
  final String userEmail;
  final List<CourseProgressDetail> courseProgresses;
  final double overallProgress;
  final int totalCourses;
  final int completedCourses;

  UserProgressDetail({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.courseProgresses,
    required this.overallProgress,
    required this.totalCourses,
    required this.completedCourses,
  });

  factory UserProgressDetail.fromMap(Map<String, dynamic> data) {
    return UserProgressDetail(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      courseProgresses: (data['courseProgresses'] as List<dynamic>?)
          ?.map((e) => CourseProgressDetail.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      overallProgress: (data['overallProgress'] ?? 0.0).toDouble(),
      totalCourses: data['totalCourses'] ?? 0,
      completedCourses: data['completedCourses'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'courseProgresses': courseProgresses.map((e) => e.toMap()).toList(),
      'overallProgress': overallProgress,
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
    };
  }
}

class CourseProgressDetail {
  final String courseId;
  final String courseTitle;
  final double progressPercentage;
  final int totalVideos;
  final int completedVideos;
  final bool isCompleted;
  final bool isCertificateEligible;
  final DateTime lastWatchedAt;

  CourseProgressDetail({
    required this.courseId,
    required this.courseTitle,
    required this.progressPercentage,
    required this.totalVideos,
    required this.completedVideos,
    required this.isCompleted,
    required this.isCertificateEligible,
    required this.lastWatchedAt,
  });

  factory CourseProgressDetail.fromMap(Map<String, dynamic> data) {
    return CourseProgressDetail(
      courseId: data['courseId'] ?? '',
      courseTitle: data['courseTitle'] ?? '',
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      totalVideos: data['totalVideos'] ?? 0,
      completedVideos: data['completedVideos'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      isCertificateEligible: data['isCertificateEligible'] ?? false,
      lastWatchedAt: (data['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'progressPercentage': progressPercentage,
      'totalVideos': totalVideos,
      'completedVideos': completedVideos,
      'isCompleted': isCompleted,
      'isCertificateEligible': isCertificateEligible,
      'lastWatchedAt': Timestamp.fromDate(lastWatchedAt),
    };
  }
}
