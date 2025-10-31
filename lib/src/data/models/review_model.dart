import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String courseId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userProfileImageUrl;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Whether user has purchased the course
  final bool isVisible; // For admin moderation
  final List<String> helpfulVotes; // User IDs who found this helpful
  final int reportCount;
  final String? adminResponse; // Admin can respond to reviews
  final DateTime? adminResponseAt;

  const ReviewModel({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImageUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
    required this.isVisible,
    required this.helpfulVotes,
    required this.reportCount,
    this.adminResponse,
    this.adminResponseAt,
  });

  // Convert from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Debug: Print the raw comment data from Firestore
    print('ReviewModel.fromFirestore: Raw comment data: "${data['comment']}"');
    print('ReviewModel.fromFirestore: Comment type: ${data['comment'].runtimeType}');
    
    return ReviewModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'],
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      isVisible: data['isVisible'] ?? true,
      helpfulVotes: List<String>.from(data['helpfulVotes'] ?? []),
      reportCount: data['reportCount'] ?? 0,
      adminResponse: data['adminResponse'],
      adminResponseAt: (data['adminResponseAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImageUrl': userProfileImageUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'isVisible': isVisible,
      'helpfulVotes': helpfulVotes,
      'reportCount': reportCount,
      'adminResponse': adminResponse,
      'adminResponseAt': adminResponseAt != null ? Timestamp.fromDate(adminResponseAt!) : null,
    };
  }

  // Copy with method
  ReviewModel copyWith({
    String? id,
    String? courseId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userProfileImageUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isVisible,
    List<String>? helpfulVotes,
    int? reportCount,
    String? adminResponse,
    DateTime? adminResponseAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isVisible: isVisible ?? this.isVisible,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      reportCount: reportCount ?? this.reportCount,
      adminResponse: adminResponse ?? this.adminResponse,
      adminResponseAt: adminResponseAt ?? this.adminResponseAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel &&
        other.id == id &&
        other.courseId == courseId &&
        other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ courseId.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'ReviewModel(id: $id, courseId: $courseId, userId: $userId, rating: $rating, comment: $comment)';
  }
}

// Course Review Summary Model
class CourseReviewSummary {
  final String courseId;
  final double averageRating;
  final int totalReviews;
  final int ratingDistribution; // JSON string of rating counts
  final int verifiedReviews;
  final DateTime lastUpdated;

  const CourseReviewSummary({
    required this.courseId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
    required this.lastUpdated,
  });

  factory CourseReviewSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseReviewSummary(
      courseId: doc.id,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: data['ratingDistribution'] ?? '{}',
      verifiedReviews: data['verifiedReviews'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'verifiedReviews': verifiedReviews,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Helper method to get rating distribution
  Map<int, int> getRatingDistribution() {
    try {
      if (ratingDistribution is String && (ratingDistribution as String).isNotEmpty) {
        // Parse JSON string to Map<String, dynamic>
        final Map<String, dynamic> jsonMap = jsonDecode(ratingDistribution as String);
        
        // Convert string keys to int keys
        final Map<int, int> result = {};
        jsonMap.forEach((key, value) {
          final intKey = int.tryParse(key);
          if (intKey != null && value is int) {
            result[intKey] = value;
          }
        });
        return result;
      } else if (ratingDistribution is Map) {
        // If it's already a Map, convert it
        final Map<int, int> result = {};
        (ratingDistribution as Map).forEach((key, value) {
          final intKey = key is int ? key : int.tryParse(key.toString());
          if (intKey != null && value is int) {
            result[intKey] = value;
          }
        });
        return result;
      }
      
      // If no distribution data, return empty map
      // The UI will handle this by showing zeros
      return {};
    } catch (e) {
      print('Error parsing rating distribution: $e');
      print('Rating distribution data: $ratingDistribution');
      return {};
    }
  }
}
