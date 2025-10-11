import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PaymentRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, _auth = auth;

  // Save payment record to Firestore
  Future<String> savePayment(PaymentModel payment) async {
    try {
      final docRef = await _firestore
          .collection('payments')
          .add(payment.toMap());
      
      print('DEBUG - Payment Repository - Payment saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('ERROR - Payment Repository - Failed to save payment: $e');
      throw Exception('Failed to save payment: $e');
    }
  }

  // Update payment status by Razorpay payment ID
  Future<void> updatePaymentStatus(String razorpayPaymentId, String status) async {
    try {
      print('DEBUG - Payment Repository - Looking for payment with Razorpay ID: $razorpayPaymentId');
      
      // First try to find by our generated payment ID
      var snapshot = await _firestore
          .collection('payments')
          .where('paymentId', isEqualTo: razorpayPaymentId)
          .get();
      
      // If not found, try to find by Razorpay payment ID (in case we stored it)
      if (snapshot.docs.isEmpty) {
        print('DEBUG - Payment Repository - Not found by paymentId, trying by razorpayPaymentId');
        snapshot = await _firestore
            .collection('payments')
            .where('razorpayPaymentId', isEqualTo: razorpayPaymentId)
            .get();
      }
      
      // If still not found, try to find any pending payment for this user (simplified query)
      if (snapshot.docs.isEmpty) {
        print('DEBUG - Payment Repository - Not found by razorpayPaymentId, trying pending payments for user');
        final user = _auth.currentUser;
        if (user != null) {
          // Get all pending payments for this user (no complex ordering to avoid index requirement)
          var pendingSnapshot = await _firestore
              .collection('payments')
              .where('userId', isEqualTo: user.uid)
              .where('paymentStatus', isEqualTo: 'pending')
              .get();
          
          // If multiple pending payments, get the most recent one by sorting in memory
          if (pendingSnapshot.docs.isNotEmpty) {
            var docs = pendingSnapshot.docs.toList();
            docs.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Most recent first
            });
            // Update the most recent pending payment
            final mostRecentDoc = docs.first;
            await mostRecentDoc.reference.update({
              'paymentStatus': status,
              'razorpayPaymentId': razorpayPaymentId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('DEBUG - Payment Repository - Updated most recent pending payment ${mostRecentDoc.id} with status: $status and Razorpay ID: $razorpayPaymentId');
            print('DEBUG - Payment Repository - Payment status updated: $razorpayPaymentId -> $status');
            return; // Exit early since we found and updated the payment
          }
        }
      }
      
      if (snapshot.docs.isEmpty) {
        print('ERROR - Payment Repository - No payment found with Razorpay ID: $razorpayPaymentId');
        throw Exception('No payment found with Razorpay ID: $razorpayPaymentId');
      }
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'paymentStatus': status,
          'razorpayPaymentId': razorpayPaymentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('DEBUG - Payment Repository - Updated document ${doc.id} with status: $status and Razorpay ID: $razorpayPaymentId');
      }
      
      print('DEBUG - Payment Repository - Payment status updated: $razorpayPaymentId -> $status');
    } catch (e) {
      print('ERROR - Payment Repository - Failed to update payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }


  // Get user's payment history
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    try {
      // Get all payments for user without ordering to avoid index requirement
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Sort in memory by createdAt (most recent first)
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('DEBUG - Payment Repository - Retrieved ${payments.length} payments for user: $userId');
      return payments;
    } catch (e) {
      print('ERROR - Payment Repository - Failed to get user payments: $e');
      throw Exception('Failed to get user payments: $e');
    }
  }

  // Get payment by payment ID
  Future<PaymentModel?> getPaymentByPaymentId(String paymentId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('paymentId', isEqualTo: paymentId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final payment = PaymentModel.fromMap({
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      });

      print('DEBUG - Payment Repository - Retrieved payment: $paymentId');
      return payment;
    } catch (e) {
      print('ERROR - Payment Repository - Failed to get payment: $e');
      throw Exception('Failed to get payment: $e');
    }
  }

  // Create payment courses from cart items
  Future<List<PaymentCourse>> createPaymentCourses(List<Map<String, dynamic>> cartItems) async {
    final now = DateTime.now();
    final List<PaymentCourse> paymentCourses = [];
    
    for (final item in cartItems) {
      try {
        // Fetch course details from courses collection to get subscriptionPeriod
        final courseSnapshot = await _firestore
            .collection('courses')
            .doc(item['courseId'])
            .get();
        
        int subscriptionPeriod = 0;
        if (courseSnapshot.exists) {
          final courseData = courseSnapshot.data();
          subscriptionPeriod = courseData?['subscriptionPeriod'] ?? 0;
        }
        
        final accessEndDate = subscriptionPeriod == 0 
            ? DateTime(2099, 12, 31) // Lifetime access
            : now.add(Duration(days: subscriptionPeriod));

        paymentCourses.add(PaymentCourse(
          courseId: item['courseId'] ?? '',
          courseTitle: item['title'] ?? '',
          instructorName: item['instructorName'] ?? item['instructor'] ?? 'Unknown',
          thumbnailUrl: item['thumbnailUrl'] ?? item['thumbnail'] ?? '',
          price: (item['price'] ?? 0.0).toDouble(),
          originalPrice: (item['originalPrice'] ?? item['price'] ?? 0.0).toDouble(),
          subscriptionPeriod: subscriptionPeriod,
          accessStartDate: now,
          accessEndDate: accessEndDate,
        ));
        
        print('DEBUG - Payment Repository - Course ${item['title']}: ${subscriptionPeriod == 0 ? 'Lifetime' : '${subscriptionPeriod} days'} access');
      } catch (e) {
        print('ERROR - Payment Repository - Failed to fetch course details for ${item['courseId']}: $e');
        // Fallback to default values if course fetch fails
        paymentCourses.add(PaymentCourse(
          courseId: item['courseId'] ?? '',
          courseTitle: item['title'] ?? '',
          instructorName: item['instructorName'] ?? item['instructor'] ?? 'Unknown',
          thumbnailUrl: item['thumbnailUrl'] ?? item['thumbnail'] ?? '',
          price: (item['price'] ?? 0.0).toDouble(),
          originalPrice: (item['originalPrice'] ?? item['price'] ?? 0.0).toDouble(),
          subscriptionPeriod: 0, // Default to lifetime if fetch fails
          accessStartDate: now,
          accessEndDate: DateTime(2099, 12, 31),
        ));
      }
    }
    
    return paymentCourses;
  }

  // Get current user data
  Map<String, String> getCurrentUserData() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return {
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': user.displayName ?? 'User',
      'userPhone': user.phoneNumber ?? '',
    };
  }

  // Generate unique payment ID
  String generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'pay_${timestamp}_$random';
  }
}
