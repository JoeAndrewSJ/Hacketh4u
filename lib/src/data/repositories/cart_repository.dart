import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Caching for performance optimization
  Map<String, Map<String, dynamic>> _courseCache = {};
  Map<String, Map<String, dynamic>> _mentorCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  CartRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore, _auth = auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Helper method to get value with fallback
  T _getValue<T>(Map<String, dynamic> data, String key, T defaultValue) {
    if (data.containsKey(key)) {
      final value = data[key];
      if (value is T) {
        return value;
      }
      // Handle type conversion for numbers
      if (T == double && value is int) {
        return (value as int).toDouble() as T;
      }
      if (T == int && value is double) {
        return (value as double).toInt() as T;
      }
      if (T == double && value is num) {
        return (value as num).toDouble() as T;
      }
      if (T == int && value is num) {
        return (value as num).toInt() as T;
      }
    }
    return defaultValue;
  }

  // Cache management methods
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  void _updateCache(Map<String, Map<String, dynamic>> courses, Map<String, Map<String, dynamic>> mentors) {
    _courseCache = courses;
    _mentorCache = mentors;
    _lastCacheUpdate = DateTime.now();
  }

  void _clearCache() {
    _courseCache.clear();
    _mentorCache.clear();
    _lastCacheUpdate = null;
  }

  // Get user's cart
  Future<List<Map<String, dynamic>>> getUserCart() async {
    if (_userId.isEmpty) return [];

    try {
      final cartSnapshot = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .orderBy('addedAt', descending: false)
          .get();

      return cartSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting user cart: $e');
      return [];
    }
  }

  // Add course to cart
  Future<bool> addToCart(Map<String, dynamic> course) async {
    if (_userId.isEmpty) return false;

    try {
      // Extract course data with proper fallbacks
      final thumbnailUrl = _getValue<String>(course, 'thumbnailUrl', '');
      final thumbnail = _getValue<String>(course, 'thumbnail', '');
      final imageUrl = _getValue<String>(course, 'imageUrl', '');
      final courseImage = _getValue<String>(course, 'courseImage', '');
      final instructor = _getValue<String>(course, 'instructor', '');
      final instructorName = _getValue<String>(course, 'instructorName', '');
      
      // Use the first available thumbnail URL
      final finalThumbnailUrl = thumbnailUrl.isNotEmpty 
          ? thumbnailUrl 
          : (thumbnail.isNotEmpty 
              ? thumbnail 
              : (imageUrl.isNotEmpty 
                  ? imageUrl 
                  : courseImage));
      
      // Use the first available instructor name, or fetch from mentor if needed
      String finalInstructor = instructor.isNotEmpty 
          ? instructor 
          : (instructorName.isNotEmpty 
              ? instructorName 
              : 'Unknown Instructor');
      
      // If still no instructor name, try to fetch from mentor data
      if (finalInstructor == 'Unknown Instructor') {
        final mentorId = _getValue<String>(course, 'mentorId', '');
        if (mentorId.isNotEmpty) {
          try {
            final mentorDoc = await _firestore.collection('mentors').doc(mentorId).get();
            if (mentorDoc.exists) {
              final mentorData = mentorDoc.data()!;
              final mentorName = _getValue<String>(mentorData, 'name', '');
              if (mentorName.isNotEmpty) {
                finalInstructor = mentorName;
              }
            }
          } catch (e) {
            print('Error fetching mentor data for instructor name: $e');
          }
        }
      }
      
      // Store only essential fields - prices will be fetched from courses collection
      final cartItem = {
        'courseId': course['id'],
        'title': _getValue<String>(course, 'title', 'Unknown Course'),
        'thumbnailUrl': finalThumbnailUrl,
        'instructorName': finalInstructor,
        'addedAt': FieldValue.serverTimestamp(),
      };
      
      // Debug logging
      print('Adding to cart - Course ID: ${course['id']}');
      print('Course title: ${cartItem['title']}');
      print('Instructor: ${cartItem['instructorName']}');
      print('Thumbnail URL: ${cartItem['thumbnailUrl']}');
      print('Cart item keys: ${cartItem.keys.toList()}');

      // Check if course already exists in cart
      final existingItem = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .where('courseId', isEqualTo: course['id'])
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Course already in cart
        return false;
      }

      // Add to cart
      await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .add(cartItem);

      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Remove course from cart
  Future<bool> removeFromCart(String cartItemId) async {
    if (_userId.isEmpty) return false;

    try {
      await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .doc(cartItemId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    print('DEBUG - Cart Repository - clearCart() called');
    print('DEBUG - Cart Repository - Current user: ${_auth.currentUser?.uid}');
    print('DEBUG - Cart Repository - User ID: $_userId');
    
    if (_userId.isEmpty) {
      print('ERROR - Cart Repository - User ID is empty, cannot clear cart');
      print('ERROR - Cart Repository - Auth current user: ${_auth.currentUser}');
      return false;
    }

    try {
      print('DEBUG - Cart Repository - Attempting to delete cart items from: carts/$_userId/items');
      
      // Get all cart items from the subcollection
      final cartItems = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .get();
      
      if (cartItems.docs.isEmpty) {
        print('WARNING - Cart Repository - No cart items found for user: $_userId');
        return true; // Consider it successful if no items exist
      }
      
      print('DEBUG - Cart Repository - Found ${cartItems.docs.length} cart items, proceeding with deletion');
      
      // Delete all cart items using batch operation
      final batch = _firestore.batch();
      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
        print('DEBUG - Cart Repository - Marking item for deletion: ${doc.id}');
      }
      
      await batch.commit();
      print('DEBUG - Cart Repository - All cart items deleted from Firestore successfully');
      return true;
    } catch (e) {
      print('ERROR - Cart Repository - Failed to delete cart items: $e');
      print('ERROR - Cart Repository - Error details: ${e.toString()}');
      return false;
    }
  }

  // Clear cart cache
  Future<void> clearCartCache() async {
    try {
      _clearCache();
      print('DEBUG - Cart Repository - Cart cache cleared successfully');
    } catch (e) {
      print('ERROR - Cart Repository - Failed to clear cart cache: $e');
      rethrow;
    }
  }

  // Check if course is in cart
  Future<bool> isInCart(String courseId) async {
    if (_userId.isEmpty) return false;

    try {
      final cartItem = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .where('courseId', isEqualTo: courseId)
          .get();

      return cartItem.docs.isNotEmpty;
    } catch (e) {
      print('Error checking cart status: $e');
      return false;
    }
  }

  // Get cart count
  Future<int> getCartCount() async {
    if (_userId.isEmpty) return 0;

    try {
      final cartItems = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .get();

      return cartItems.docs.length;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Stream cart items for real-time updates
  Stream<List<Map<String, dynamic>>> getCartStream() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .orderBy('addedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Fetch complete course data for cart items (OPTIMIZED WITH CACHING)
  Future<List<Map<String, dynamic>>> getCartItemsWithCourseData() async {
    if (_userId.isEmpty) return [];

    try {
      final cartItems = await getUserCart();
      if (cartItems.isEmpty) return [];

      // Check if we can use cached data
      Map<String, Map<String, dynamic>> coursesMap;
      Map<String, Map<String, dynamic>> mentorsMap;

      if (_isCacheValid()) {
        // Use cached data for better performance
        coursesMap = _courseCache;
        mentorsMap = _mentorCache;
        print('Using cached data for cart items');
      } else {
        // OPTIMIZATION: Batch fetch all courses at once
        final courseIds = cartItems.map((item) => item['courseId']).toList();
        final coursesSnapshot = await _firestore
            .collection('courses')
            .where(FieldPath.documentId, whereIn: courseIds)
            .get();

        // Create a map for quick course lookup
        coursesMap = <String, Map<String, dynamic>>{};
        print('DEBUG - Fetched ${coursesSnapshot.docs.length} courses from database');
        for (final doc in coursesSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          coursesMap[doc.id] = data;
          print('DEBUG - Course ${doc.id}: price=${data['price']}, originalPrice=${data['originalPrice']}');
        }

        // OPTIMIZATION: Batch fetch all mentors at once
        final mentorIds = <String>{};
        for (final courseData in coursesMap.values) {
          final mentorId = _getValue<String>(courseData, 'mentorId', '');
          if (mentorId.isNotEmpty) {
            mentorIds.add(mentorId);
          }
        }

        mentorsMap = <String, Map<String, dynamic>>{};
        if (mentorIds.isNotEmpty) {
          final mentorsSnapshot = await _firestore
              .collection('mentors')
              .where(FieldPath.documentId, whereIn: mentorIds.toList())
              .get();

          for (final doc in mentorsSnapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            mentorsMap[doc.id] = data;
          }
        }

        // Update cache with fresh data
        _updateCache(coursesMap, mentorsMap);
        print('Fetched fresh data and updated cache');
      }

      // Enrich cart items with batch-fetched data
      final enrichedCartItems = <Map<String, dynamic>>[];
      print('DEBUG - Processing ${cartItems.length} cart items');
      for (final cartItem in cartItems) {
        final courseId = cartItem['courseId'];
        print('DEBUG - Processing cart item with courseId: $courseId');
        print('DEBUG - Cart item: $cartItem');
        final courseData = coursesMap[courseId];
        
        if (courseData != null) {
          print('DEBUG - Found course data for ID: $courseId');
          print('DEBUG - Course data: $courseData');
          final enrichedItem = Map<String, dynamic>.from(cartItem);
          
          // Update thumbnail with latest course data
          final courseThumbnailUrl = _getValue<String>(courseData, 'thumbnailUrl', '');
          final courseThumbnail = _getValue<String>(courseData, 'thumbnail', '');
          final courseImageUrl = _getValue<String>(courseData, 'imageUrl', '');
          
          if (courseThumbnailUrl.isNotEmpty || courseThumbnail.isNotEmpty || courseImageUrl.isNotEmpty) {
            final bestThumbnail = courseThumbnailUrl.isNotEmpty 
                ? courseThumbnailUrl 
                : (courseThumbnail.isNotEmpty 
                    ? courseThumbnail 
                    : courseImageUrl);
            
            enrichedItem['thumbnailUrl'] = bestThumbnail;
            enrichedItem['thumbnail'] = bestThumbnail;
            enrichedItem['imageUrl'] = bestThumbnail;
            enrichedItem['courseImage'] = bestThumbnail;
          }
          
          // Update instructor with latest data
          final courseInstructor = _getValue<String>(courseData, 'instructor', '');
          final courseInstructorName = _getValue<String>(courseData, 'instructorName', '');
          final mentorId = _getValue<String>(courseData, 'mentorId', '');
          
          String bestInstructor = '';
          if (courseInstructor.isNotEmpty) {
            bestInstructor = courseInstructor;
          } else if (courseInstructorName.isNotEmpty) {
            bestInstructor = courseInstructorName;
          } else if (mentorId.isNotEmpty) {
            final mentorData = mentorsMap[mentorId];
            if (mentorData != null) {
              bestInstructor = _getValue<String>(mentorData, 'name', '');
            }
          }
          
          if (bestInstructor.isNotEmpty) {
            enrichedItem['instructor'] = bestInstructor;
            enrichedItem['instructorName'] = bestInstructor;
          }
          
          // CRITICAL: Fetch prices from courses collection (always up-to-date)
          final coursePrice = _getValue<double>(courseData, 'price', 0.0);
          final courseOriginalPrice = _getValue<double>(courseData, 'originalPrice', coursePrice);
          
          print('DEBUG - Course ID: ${courseId}');
          print('DEBUG - Course data keys: ${courseData.keys.toList()}');
          print('DEBUG - Raw price from course: ${courseData['price']}');
          print('DEBUG - Raw originalPrice from course: ${courseData['originalPrice']}');
          print('DEBUG - Parsed price: $coursePrice');
          print('DEBUG - Parsed originalPrice: $courseOriginalPrice');
          
          enrichedItem['price'] = coursePrice;
          enrichedItem['originalPrice'] = courseOriginalPrice;
          
          // Update other fields with latest data from courses collection
          enrichedItem['title'] = _getValue<String>(courseData, 'title', enrichedItem['title']);
          enrichedItem['duration'] = _getValue<int>(courseData, 'duration', _getValue<int>(courseData, 'totalDuration', 0));
          enrichedItem['rating'] = _getValue<double>(courseData, 'rating', 0.0);
          enrichedItem['students'] = _getValue<int>(courseData, 'students', _getValue<int>(courseData, 'enrolledCount', 0));
          
          enrichedCartItems.add(enrichedItem);
        } else {
          // Course not found, use cart item as is
          enrichedCartItems.add(cartItem);
        }
      }

      return enrichedCartItems;
    } catch (e) {
      print('Error getting cart items with course data: $e');
      return [];
    }
  }

  // Force refresh cache when course data is updated
  void refreshCache() {
    _clearCache();
    print('Cache cleared - will fetch fresh data on next request');
  }

  // Get cart items with forced refresh (for price updates)
  Future<List<Map<String, dynamic>>> getCartItemsWithFreshData() async {
    _clearCache();
    return getCartItemsWithCourseData();
  }
}
