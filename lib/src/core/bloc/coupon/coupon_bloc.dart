import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'coupon_event.dart';
import 'coupon_state.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final FirebaseFirestore _firestore;
  final Random _random;

  CouponBloc({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore,
        _random = Random(),
        super(const CouponState()) {
    print('DEBUG - CouponBloc - Initializing with state: ${state.runtimeType}');
    print('DEBUG - CouponBloc - Initial appliedCoupon: ${state.appliedCoupon}');
    print('DEBUG - CouponBloc - Initial discountAmount: ${state.discountAmount}');
    
    on<CreateCoupon>(_onCreateCoupon);
    on<UpdateCoupon>(_onUpdateCoupon);
    on<DeleteCoupon>(_onDeleteCoupon);
    on<LoadCoupons>(_onLoadCoupons);
    on<ValidateCoupon>(_onValidateCoupon);
    on<ApplyCoupon>(_onApplyCoupon);
    on<RemoveCoupon>(_onRemoveCoupon);
  }

  Future<void> _onCreateCoupon(CreateCoupon event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final couponId = _generateId();
      final couponData = {
        'id': couponId,
        'code': event.couponData['code'],
        'discountPercentage': event.couponData['discountPercentage'],
        'courseId': event.couponData['courseId'],
        'courseTitle': event.couponData['courseTitle'],
        'validUntil': event.couponData['validUntil'],
        'isActive': event.couponData['isActive'] ?? true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('coupons')
          .doc(couponId)
          .set(couponData);

      emit(CouponCreated(coupon: couponData));
    } catch (e) {
      emit(CouponError(error: e.toString()));
    }
  }

  Future<void> _onUpdateCoupon(UpdateCoupon event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final updateData = {
        ...event.couponData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('coupons')
          .doc(event.couponId)
          .update(updateData);

      final updatedCoupon = {
        'id': event.couponId,
        ...updateData,
      };

      emit(CouponUpdated(coupon: updatedCoupon));
    } catch (e) {
      emit(CouponError(error: e.toString()));
    }
  }

  Future<void> _onDeleteCoupon(DeleteCoupon event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      await _firestore
          .collection('coupons')
          .doc(event.couponId)
          .delete();

      emit(CouponDeleted(couponId: event.couponId));
    } catch (e) {
      emit(CouponError(error: e.toString()));
    }
  }

  Future<void> _onLoadCoupons(LoadCoupons event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .orderBy('createdAt', descending: true)
          .get();

      final coupons = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      emit(CouponsLoaded(coupons: coupons));
    } catch (e) {
      emit(CouponError(error: e.toString()));
    }
  }

  Future<void> _onValidateCoupon(ValidateCoupon event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      // Find coupon by code
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: event.couponCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        emit(CouponError(error: 'Coupon not found or inactive'));
        return;
      }

      final coupon = {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };

      // Check if coupon is valid for any of the course IDs
      final courseId = coupon['courseId'];
      if (courseId != null && !event.courseIds.contains(courseId)) {
        emit(CouponError(error: 'Coupon not applicable for selected courses'));
        return;
      }

      // Check if coupon is still valid
      final validUntil = coupon['validUntil'];
      if (validUntil != null) {
        final validUntilDate = validUntil.toDate();
        if (DateTime.now().isAfter(validUntilDate)) {
          emit(CouponError(error: 'Coupon has expired'));
          return;
        }
      }

      emit(CouponValidated(coupon: coupon, discountAmount: 0.0));
    } catch (e) {
      emit(CouponError(error: 'Error validating coupon: ${e.toString()}'));
    }
  }

  Future<void> _onApplyCoupon(ApplyCoupon event, Emitter<CouponState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      // Find coupon by code
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: event.couponCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        emit(CouponError(error: 'Coupon not found'));
        return;
      }

      final coupon = {
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      };
      
      print('DEBUG - Coupon Bloc - Coupon data: $coupon');
      print('DEBUG - Coupon Bloc - Coupon keys: ${coupon.keys.toList()}');
      print('DEBUG - Coupon Bloc - Discount percentage in coupon: ${coupon['discountPercentage']} (type: ${coupon['discountPercentage'].runtimeType})');

      // Check if coupon is active
      final isActive = coupon['isActive'];
      if (isActive != true) {
        print('DEBUG - Coupon Bloc - Coupon is not active');
        emit(CouponError(error: 'This coupon is not active'));
        return;
      }

      // Check if coupon is still valid (not expired)
      final validUntil = coupon['validUntil'];
      if (validUntil != null) {
        final validUntilDate = validUntil.toDate();
        if (DateTime.now().isAfter(validUntilDate)) {
          print('DEBUG - Coupon Bloc - Coupon has expired');
          emit(CouponError(error: 'This coupon has expired'));
          return;
        }
      }

      // Validate if coupon is for the specific course in cart
      final couponCourseId = coupon['courseId'];
      print('DEBUG - Coupon Bloc - Coupon courseId: $couponCourseId');
      
      // Check if any cart item matches the coupon's courseId
      bool isCouponValidForCart = false;
      for (final item in event.cartItems) {
        final itemCourseId = item['courseId'];
        print('DEBUG - Coupon Bloc - Cart item courseId: $itemCourseId');
        if (itemCourseId == couponCourseId) {
          isCouponValidForCart = true;
          break;
        }
      }
      
      if (!isCouponValidForCart) {
        print('DEBUG - Coupon Bloc - Coupon not valid for any course in cart');
        emit(CouponError(error: 'This coupon is not valid for any course in your cart'));
        return;
      }
      
      print('DEBUG - Coupon Bloc - Coupon is valid for cart items');

      // Calculate total cart amount and amount for the specific course
      double totalCartAmount = 0.0;
      double applicableCourseAmount = 0.0;
      print('DEBUG - Calculating total for ${event.cartItems.length} cart items');
      
      for (final item in event.cartItems) {
        final price = item['price'];
        final itemCourseId = item['courseId'];
        print('DEBUG - Price value: $price (type: ${price.runtimeType}) for course: $itemCourseId');
        
        double itemPrice = 0.0;
        if (price is double) {
          itemPrice = price;
        } else if (price is int) {
          itemPrice = price.toDouble();
        } else if (price is num) {
          itemPrice = price.toDouble();
        }
        
        // Add to total cart amount
        totalCartAmount += itemPrice;
        
        // Add to applicable course amount if it matches the coupon's courseId
        if (itemCourseId == couponCourseId) {
          applicableCourseAmount += itemPrice;
        }
      }
      
      print('DEBUG - Total cart amount: $totalCartAmount');
      print('DEBUG - Applicable course amount: $applicableCourseAmount');

      // Calculate discount only on the applicable course amount
      final discountPercentageValue = coupon['discountPercentage'];
      print('DEBUG - Discount percentage value: $discountPercentageValue (type: ${discountPercentageValue.runtimeType})');
      double discountPercentage = 0.0;
      if (discountPercentageValue is double) {
        discountPercentage = discountPercentageValue;
      } else if (discountPercentageValue is int) {
        discountPercentage = discountPercentageValue.toDouble();
      } else if (discountPercentageValue is num) {
        discountPercentage = discountPercentageValue.toDouble();
      }
      print('DEBUG - Parsed discount percentage: $discountPercentage');
      
      final discountAmount = (applicableCourseAmount * discountPercentage) / 100;
      final totalAfterDiscount = totalCartAmount - discountAmount;
      
      print('DEBUG - MATH CHECK:');
      print('DEBUG - Applicable Course Amount: $applicableCourseAmount');
      print('DEBUG - Discount Percentage: $discountPercentage%');
      print('DEBUG - Discount Calculation: ($applicableCourseAmount * $discountPercentage) / 100 = $discountAmount');
      print('DEBUG - Total Cart Amount: $totalCartAmount');
      print('DEBUG - Final Calculation: $totalCartAmount - $discountAmount = $totalAfterDiscount');

      emit(CouponApplied(
        coupon: coupon,
        discountAmount: discountAmount,
        totalAfterDiscount: totalAfterDiscount,
      ));
    } catch (e) {
      emit(CouponError(error: 'Error applying coupon: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveCoupon(RemoveCoupon event, Emitter<CouponState> emit) async {
    print('DEBUG - Remove Coupon - Current state: ${state.runtimeType}');
    print('DEBUG - Remove Coupon - Current appliedCoupon: ${state.appliedCoupon}');
    print('DEBUG - Remove Coupon - Current discountAmount: ${state.discountAmount}');
    
    // Emit a fresh initial state instead of using copyWith
    emit(const CouponState());
    
    print('DEBUG - Remove Coupon - Fresh initial state emitted');
  }

  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(8, (index) => chars[_random.nextInt(chars.length)]).join();
    return '${timestamp}_$randomPart';
  }
}
