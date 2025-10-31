import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import 'course_repository.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CourseRepository _courseRepository;

  ReviewRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required CourseRepository courseRepository,
  }) : _firestore = firestore, _auth = auth, _courseRepository = courseRepository;

  // Collection references
  static const String _reviewsCollection = 'reviews';
  static const String _courseReviewsCollection = 'course_reviews';
  static const String _usersCollection = 'users';

  /// Get all reviews for a course with pagination and sorting
  Future<List<ReviewModel>> getCourseReviews({
    required String courseId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String sortBy = 'createdAt', // createdAt, rating, helpfulVotes
    bool ascending = false, // false for newest first
    bool onlyVerified = false,
  }) async {
    try {
      print('ReviewRepository: Fetching reviews for course: $courseId');

      // Simple query with just courseId filter to avoid composite index requirement
      Query query = _firestore
          .collection(_reviewsCollection)
          .where('courseId', isEqualTo: courseId)
          .limit(limit * 3); // Get more to account for client-side filtering and sorting

      final querySnapshot = await query.get();
      
      // Filter and sort client-side to avoid composite index
      List<ReviewModel> allReviews = querySnapshot.docs
          .map((doc) {
            final review = ReviewModel.fromFirestore(doc);
            print('ReviewRepository: Review comment: "${review.comment}"');
            print('ReviewRepository: Review comment length: ${review.comment.length}');
            return review;
          })
          .toList();

      // Apply filters - show all reviews regardless of visibility
      List<ReviewModel> filteredReviews = allReviews
          .where((review) => onlyVerified ? review.isVerified : true)
          .toList();

      // Sort client-side
      filteredReviews.sort((a, b) {
        if (sortBy == 'createdAt') {
          return ascending 
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        } else if (sortBy == 'rating') {
          return ascending 
              ? a.rating.compareTo(b.rating)
              : b.rating.compareTo(a.rating);
        } else if (sortBy == 'helpfulVotes') {
          return ascending 
              ? a.helpfulVotes.length.compareTo(b.helpfulVotes.length)
              : b.helpfulVotes.length.compareTo(a.helpfulVotes.length);
        }
        return 0;
      });

      // Apply limit
      filteredReviews = filteredReviews.take(limit).toList();

      print('ReviewRepository: Found ${filteredReviews.length} reviews for course $courseId');
      return filteredReviews;
    } catch (e) {
      print('ReviewRepository: Error fetching course reviews: $e');
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Get user's review for a specific course
  Future<ReviewModel?> getUserReviewForCourse({
    required String courseId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return null;

      print('ReviewRepository: Fetching user review for course: $courseId, user: $uid');

      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('courseId', isEqualTo: courseId)
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ReviewRepository: No review found for user $uid in course $courseId');
        return null;
      }

      final review = ReviewModel.fromFirestore(querySnapshot.docs.first);
      print('ReviewRepository: Found existing review for user $uid in course $courseId');
      return review;
    } catch (e) {
      print('ReviewRepository: Error fetching user review: $e');
      throw Exception('Failed to fetch user review: $e');
    }
  }

  /// Create or update a review
  Future<ReviewModel> createOrUpdateReview({
    required String courseId,
    required int rating,
    required String comment,
    String? userId,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('ReviewRepository: Creating/updating review for course: $courseId, user: $uid');

      // Get user data
      final userDoc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Anonymous';
      final userEmail = userData['email'] ?? '';
      final userProfileImageUrl = userData['profileImageUrl'];

      // Check if user has purchased the course (for verification)
      final isVerified = await _checkUserCourseAccess(uid, courseId);

      // Check if review already exists
      final existingReview = await getUserReviewForCourse(courseId: courseId, userId: uid);

      final now = DateTime.now();
      ReviewModel review;

      if (existingReview != null) {
        // Update existing review
        review = existingReview.copyWith(
          rating: rating,
          comment: comment,
          updatedAt: now,
          isVerified: isVerified,
        );
        await _firestore
            .collection(_reviewsCollection)
            .doc(existingReview.id)
            .update(review.toFirestore());
        print('ReviewRepository: Updated existing review for user $uid');
      } else {
        // Create new review
        review = ReviewModel(
          id: '', // Will be set by Firestore
          courseId: courseId,
          userId: uid,
          userName: userName,
          userEmail: userEmail,
          userProfileImageUrl: userProfileImageUrl,
          rating: rating,
          comment: comment,
          createdAt: now,
          updatedAt: now,
          isVerified: isVerified,
          isVisible: true,
          helpfulVotes: [],
          reportCount: 0,
        );

        final docRef = await _firestore
            .collection(_reviewsCollection)
            .add(review.toFirestore());
        
        review = review.copyWith(id: docRef.id);
        print('ReviewRepository: Created new review for user $uid');
      }

      // Update course review summary
      await _updateCourseReviewSummary(courseId);

      return review;
    } catch (e) {
      print('ReviewRepository: Error creating/updating review: $e');
      throw Exception('Failed to save review: $e');
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      print('ReviewRepository: Deleting review: $reviewId');

      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final reviewData = reviewDoc.data()!;
      final courseId = reviewData['courseId'] as String;

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .delete();

      // Update course review summary
      await _updateCourseReviewSummary(courseId);

      print('ReviewRepository: Deleted review: $reviewId');
    } catch (e) {
      print('ReviewRepository: Error deleting review: $e');
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Vote for a review (helpful/not helpful)
  Future<void> voteForReview({
    required String reviewId,
    required bool isHelpful,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('ReviewRepository: Voting for review: $reviewId, helpful: $isHelpful');

      final reviewRef = _firestore.collection(_reviewsCollection).doc(reviewId);
      
      await _firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        if (!reviewDoc.exists) {
          throw Exception('Review not found');
        }

        final reviewData = reviewDoc.data()!;
        final helpfulVotes = List<String>.from(reviewData['helpfulVotes'] ?? []);

        if (isHelpful) {
          if (!helpfulVotes.contains(uid)) {
            helpfulVotes.add(uid);
          }
        } else {
          helpfulVotes.remove(uid);
        }

        transaction.update(reviewRef, {
          'helpfulVotes': helpfulVotes,
        });
      });

      print('ReviewRepository: Successfully voted for review: $reviewId');
    } catch (e) {
      print('ReviewRepository: Error voting for review: $e');
      throw Exception('Failed to vote for review: $e');
    }
  }

  /// Report a review
  Future<void> reportReview(String reviewId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('ReviewRepository: Reporting review: $reviewId');

      await _firestore.collection('review_reports').add({
        'reviewId': reviewId,
        'reportedBy': uid,
        'reason': 'Inappropriate content',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment report count
      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update({
        'reportCount': FieldValue.increment(1),
      });

      print('ReviewRepository: Successfully reported review: $reviewId');
    } catch (e) {
      print('ReviewRepository: Error reporting review: $e');
      throw Exception('Failed to report review: $e');
    }
  }

  /// Get course review summary
  Future<CourseReviewSummary?> getCourseReviewSummary(String courseId) async {
    try {
      print('ReviewRepository: Fetching review summary for course: $courseId');

      final doc = await _firestore
          .collection(_courseReviewsCollection)
          .doc(courseId)
          .get();

      if (!doc.exists) {
        print('ReviewRepository: No review summary found for course $courseId');
        return null;
      }

      final summary = CourseReviewSummary.fromFirestore(doc);
      print('ReviewRepository: Found review summary for course $courseId: ${summary.totalReviews} reviews, ${summary.averageRating} avg rating');
      return summary;
    } catch (e) {
      print('ReviewRepository: Error fetching review summary: $e');
      throw Exception('Failed to fetch review summary: $e');
    }
  }

  /// Check if user has access to the course (for verification)
  Future<bool> _checkUserCourseAccess(String userId, String courseId) async {
    try {
      // Check if user has any completed payment for this course
      final paymentQuery = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      for (var paymentDoc in paymentQuery.docs) {
        final paymentData = paymentDoc.data();
        final courses = paymentData['courses'] as List<dynamic>? ?? [];
        
        for (var course in courses) {
          final courseMap = course as Map<String, dynamic>;
          final purchasedCourseId = courseMap['courseId'] as String?;
          final accessEndDate = courseMap['accessEndDate'] as Timestamp?;
          
          if (purchasedCourseId == courseId) {
            // Check if access is still valid
            if (accessEndDate != null) {
              final now = DateTime.now();
              final endDate = accessEndDate.toDate();
              
              if (now.isBefore(endDate)) {
                return true;
              }
            } else {
              // No end date means lifetime access
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print('ReviewRepository: Error checking course access: $e');
      return false;
    }
  }

  /// Update course review summary (called after review operations)
  Future<void> _updateCourseReviewSummary(String courseId) async {
    try {
      print('ReviewRepository: Updating review summary for course: $courseId');

      // Get all reviews for this course (filter visibility client-side)
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('courseId', isEqualTo: courseId)
          .get();

      final allReviews = reviewsSnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      // Use all reviews for summary calculation (no visibility filter)
      final reviews = allReviews;

      if (reviews.isEmpty) {
        // Delete the summary document if no reviews
        await _firestore
            .collection(_courseReviewsCollection)
            .doc(courseId)
            .delete();
        print('ReviewRepository: Deleted empty review summary for course $courseId');
        return;
      }

      // Calculate summary statistics
      final totalReviews = reviews.length;
      final verifiedReviews = reviews.where((r) => r.isVerified).length;
      
      // Calculate average rating (convert int ratings to double for proper calculation)
      double totalRatingSum = 0.0;
      for (final review in reviews) {
        totalRatingSum += review.rating.toDouble();
      }
      final averageRating = totalReviews > 0 ? totalRatingSum / totalReviews : 0.0;
      
      print('ReviewRepository: Rating calculation - Total reviews: $totalReviews, Sum: $totalRatingSum, Average: $averageRating');

      // Calculate rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      // Update or create summary document
      final summary = CourseReviewSummary(
        courseId: courseId,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: 0, // Simplified for now - you can implement proper JSON serialization
        verifiedReviews: verifiedReviews,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_courseReviewsCollection)
          .doc(courseId)
          .set(summary.toFirestore(), SetOptions(merge: true));

      // Update the course's rating in the courses collection
      await _courseRepository.updateCourseRating(courseId, averageRating, totalReviews);

      print('ReviewRepository: Updated review summary for course $courseId: $totalReviews reviews, $averageRating avg rating');
    } catch (e) {
      print('ReviewRepository: Error updating review summary: $e');
      // Don't throw here as this is a background operation
    }
  }

  /// Manually update course rating for existing courses (utility method)
  Future<void> updateAllCourseRatings() async {
    try {
      print('ReviewRepository: Starting bulk course rating update...');
      
      // Get all courses
      final coursesSnapshot = await _firestore.collection('courses').get();
      
      for (final courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;
        final courseData = courseDoc.data();
        
        print('ReviewRepository: Processing course: ${courseData['title']} ($courseId)');
        
        // Update the course rating
        await _updateCourseReviewSummary(courseId);
      }
      
      print('ReviewRepository: Completed bulk course rating update');
    } catch (e) {
      print('ReviewRepository: Error in bulk course rating update: $e');
      throw Exception('Failed to update all course ratings: $e');
    }
  }

  /// Get recent reviews across all courses (for admin)
  Future<List<ReviewModel>> getRecentReviews({
    int limit = 50,
    bool onlyReported = false,
  }) async {
    try {
      print('ReviewRepository: Fetching recent reviews, limit: $limit, reported only: $onlyReported');

      // Simple query without orderBy to avoid index requirement
      Query query = _firestore
          .collection(_reviewsCollection)
          .limit(onlyReported ? limit * 5 : limit * 2); // Get more for client-side filtering and sorting

      final querySnapshot = await query.get();
      final allReviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      // Filter and sort client-side
      List<ReviewModel> filteredReviews = allReviews;
      if (onlyReported) {
        filteredReviews = allReviews.where((review) => review.reportCount > 0).toList();
      }

      // Sort by createdAt descending (most recent first)
      filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit
      filteredReviews = filteredReviews.take(limit).toList();

      print('ReviewRepository: Found ${filteredReviews.length} recent reviews');
      return filteredReviews;
    } catch (e) {
      print('ReviewRepository: Error fetching recent reviews: $e');
      throw Exception('Failed to fetch recent reviews: $e');
    }
  }

  /// Admin: Hide/Show a review
  Future<void> toggleReviewVisibility(String reviewId, bool isVisible) async {
    try {
      print('ReviewRepository: Toggling review visibility: $reviewId, visible: $isVisible');

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update({
        'isVisible': isVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the course ID to update summary
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (reviewDoc.exists) {
        final reviewData = reviewDoc.data()!;
        final courseId = reviewData['courseId'] as String;
        await _updateCourseReviewSummary(courseId);
      }

      print('ReviewRepository: Successfully toggled review visibility: $reviewId');
    } catch (e) {
      print('ReviewRepository: Error toggling review visibility: $e');
      throw Exception('Failed to toggle review visibility: $e');
    }
  }

  /// Admin: Add response to a review
  Future<void> addAdminResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      print('ReviewRepository: Adding admin response to review: $reviewId');

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update({
        'adminResponse': response,
        'adminResponseAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('ReviewRepository: Successfully added admin response to review: $reviewId');
    } catch (e) {
      print('ReviewRepository: Error adding admin response: $e');
      throw Exception('Failed to add admin response: $e');
    }
  }
}
