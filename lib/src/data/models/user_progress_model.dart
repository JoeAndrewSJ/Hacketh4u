import 'package:cloud_firestore/cloud_firestore.dart';

class VideoProgress {
  final String videoId;
  final String videoTitle;
  final double watchPercentage; // 0.0 to 100.0
  final Duration watchedDuration;
  final Duration totalDuration;
  final DateTime lastWatchedAt;
  final bool isCompleted;

  const VideoProgress({
    required this.videoId,
    required this.videoTitle,
    required this.watchPercentage,
    required this.watchedDuration,
    required this.totalDuration,
    required this.lastWatchedAt,
    required this.isCompleted,
  });

  factory VideoProgress.fromMap(Map<String, dynamic> data) {
    return VideoProgress(
      videoId: data['videoId'] as String,
      videoTitle: data['videoTitle'] as String,
      watchPercentage: (data['watchPercentage'] as num).toDouble(),
      watchedDuration: Duration(seconds: data['watchedDurationSeconds'] as int),
      totalDuration: Duration(seconds: data['totalDurationSeconds'] as int),
      lastWatchedAt: (data['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoTitle': videoTitle,
      'watchPercentage': watchPercentage,
      'watchedDurationSeconds': watchedDuration.inSeconds,
      'totalDurationSeconds': totalDuration.inSeconds,
      'lastWatchedAt': Timestamp.fromDate(lastWatchedAt),
      'isCompleted': isCompleted,
    };
  }

  VideoProgress copyWith({
    String? videoId,
    String? videoTitle,
    double? watchPercentage,
    Duration? watchedDuration,
    Duration? totalDuration,
    DateTime? lastWatchedAt,
    bool? isCompleted,
  }) {
    return VideoProgress(
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      watchPercentage: watchPercentage ?? this.watchPercentage,
      watchedDuration: watchedDuration ?? this.watchedDuration,
      totalDuration: totalDuration ?? this.totalDuration,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String moduleTitle;
  final Map<String, VideoProgress> videoProgresses;
  final double completionPercentage;
  final bool isCompleted;

  const ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    required this.videoProgresses,
    required this.completionPercentage,
    required this.isCompleted,
  });

  factory ModuleProgress.fromMap(Map<String, dynamic> data) {
    final videoProgressMap = <String, VideoProgress>{};
    if (data['videoProgresses'] != null) {
      (data['videoProgresses'] as Map<String, dynamic>).forEach((key, value) {
        videoProgressMap[key] = VideoProgress.fromMap(value as Map<String, dynamic>);
      });
    }

    return ModuleProgress(
      moduleId: data['moduleId'] as String,
      moduleTitle: data['moduleTitle'] as String,
      videoProgresses: videoProgressMap,
      completionPercentage: (data['completionPercentage'] as num).toDouble(),
      isCompleted: data['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    final videoProgressMap = <String, Map<String, dynamic>>{};
    videoProgresses.forEach((key, value) {
      videoProgressMap[key] = value.toMap();
    });

    return {
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'videoProgresses': videoProgressMap,
      'completionPercentage': completionPercentage,
      'isCompleted': isCompleted,
    };
  }

  ModuleProgress copyWith({
    String? moduleId,
    String? moduleTitle,
    Map<String, VideoProgress>? videoProgresses,
    double? completionPercentage,
    bool? isCompleted,
  }) {
    return ModuleProgress(
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      videoProgresses: videoProgresses ?? this.videoProgresses,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class UserProgressModel {
  final String id;
  final String userId;
  final String courseId;
  final String courseTitle;
  final Map<String, ModuleProgress> moduleProgresses;
  final double overallCompletionPercentage;
  final bool isCourseCompleted;
  final bool isCertificateEligible;
  final bool isCertificateDownloaded;
  final DateTime? certificateDownloadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProgressModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.moduleProgresses,
    required this.overallCompletionPercentage,
    required this.isCourseCompleted,
    required this.isCertificateEligible,
    required this.isCertificateDownloaded,
    this.certificateDownloadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final moduleProgressMap = <String, ModuleProgress>{};
    if (data['moduleProgresses'] != null) {
      (data['moduleProgresses'] as Map<String, dynamic>).forEach((key, value) {
        moduleProgressMap[key] = ModuleProgress.fromMap(value as Map<String, dynamic>);
      });
    }

    return UserProgressModel(
      id: doc.id,
      userId: data['userId'] as String,
      courseId: data['courseId'] as String,
      courseTitle: data['courseTitle'] as String,
      moduleProgresses: moduleProgressMap,
      overallCompletionPercentage: (data['overallCompletionPercentage'] as num).toDouble(),
      isCourseCompleted: data['isCourseCompleted'] as bool,
      isCertificateEligible: data['isCertificateEligible'] as bool,
      isCertificateDownloaded: data['isCertificateDownloaded'] as bool,
      certificateDownloadedAt: (data['certificateDownloadedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final moduleProgressMap = <String, Map<String, dynamic>>{};
    moduleProgresses.forEach((key, value) {
      moduleProgressMap[key] = value.toMap();
    });

    return {
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'moduleProgresses': moduleProgressMap,
      'overallCompletionPercentage': overallCompletionPercentage,
      'isCourseCompleted': isCourseCompleted,
      'isCertificateEligible': isCertificateEligible,
      'isCertificateDownloaded': isCertificateDownloaded,
      'certificateDownloadedAt': certificateDownloadedAt != null 
          ? Timestamp.fromDate(certificateDownloadedAt!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProgressModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? courseTitle,
    Map<String, ModuleProgress>? moduleProgresses,
    double? overallCompletionPercentage,
    bool? isCourseCompleted,
    bool? isCertificateEligible,
    bool? isCertificateDownloaded,
    DateTime? certificateDownloadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      moduleProgresses: moduleProgresses ?? this.moduleProgresses,
      overallCompletionPercentage: overallCompletionPercentage ?? this.overallCompletionPercentage,
      isCourseCompleted: isCourseCompleted ?? this.isCourseCompleted,
      isCertificateEligible: isCertificateEligible ?? this.isCertificateEligible,
      isCertificateDownloaded: isCertificateDownloaded ?? this.isCertificateDownloaded,
      certificateDownloadedAt: certificateDownloadedAt ?? this.certificateDownloadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CourseProgressSummary {
  final String courseId;
  final String courseTitle;
  final int totalVideos;
  final int completedVideos;
  final double averageCompletionPercentage;
  final bool isCertificateEligible;
  final bool isCertificateDownloaded;
  final String? certificateTemplateUrl;

  const CourseProgressSummary({
    required this.courseId,
    required this.courseTitle,
    required this.totalVideos,
    required this.completedVideos,
    required this.averageCompletionPercentage,
    required this.isCertificateEligible,
    required this.isCertificateDownloaded,
    this.certificateTemplateUrl,
  });

  factory CourseProgressSummary.fromMap(Map<String, dynamic> data) {
    return CourseProgressSummary(
      courseId: data['courseId'] as String,
      courseTitle: data['courseTitle'] as String,
      totalVideos: data['totalVideos'] as int,
      completedVideos: data['completedVideos'] as int,
      averageCompletionPercentage: (data['averageCompletionPercentage'] as num).toDouble(),
      isCertificateEligible: data['isCertificateEligible'] as bool,
      isCertificateDownloaded: data['isCertificateDownloaded'] as bool? ?? false,
      certificateTemplateUrl: data['certificateTemplateUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'totalVideos': totalVideos,
      'completedVideos': completedVideos,
      'averageCompletionPercentage': averageCompletionPercentage,
      'isCertificateEligible': isCertificateEligible,
      'isCertificateDownloaded': isCertificateDownloaded,
      'certificateTemplateUrl': certificateTemplateUrl,
    };
  }
}
