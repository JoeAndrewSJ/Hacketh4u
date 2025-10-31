import 'package:equatable/equatable.dart';

class CouponState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> coupons;
  final Map<String, dynamic>? currentCoupon;
  final Map<String, dynamic>? appliedCoupon;
  final double discountAmount;
  final List<Map<String, dynamic>> applicableCoupons;

  const CouponState({
    this.isLoading = false,
    this.errorMessage,
    this.coupons = const [],
    this.currentCoupon,
    this.appliedCoupon,
    this.discountAmount = 0.0,
    this.applicableCoupons = const [],
  });

  CouponState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? coupons,
    Map<String, dynamic>? currentCoupon,
    Map<String, dynamic>? appliedCoupon,
    double? discountAmount,
    List<Map<String, dynamic>>? applicableCoupons,
  }) {
    return CouponState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      coupons: coupons ?? this.coupons,
      currentCoupon: currentCoupon ?? this.currentCoupon,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      discountAmount: discountAmount ?? this.discountAmount,
      applicableCoupons: applicableCoupons ?? this.applicableCoupons,
    );
  }

  @override
  List<Object?> get props => [
    isLoading, 
    errorMessage, 
    coupons, 
    currentCoupon, 
    appliedCoupon, 
    discountAmount, 
    applicableCoupons
  ];
}

// Coupon Events
class CouponCreated extends CouponState {
  final Map<String, dynamic> coupon;

  const CouponCreated({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponUpdated extends CouponState {
  final Map<String, dynamic> coupon;

  const CouponUpdated({required this.coupon});

  @override
  List<Object?> get props => [coupon];
}

class CouponDeleted extends CouponState {
  final String couponId;

  const CouponDeleted({required this.couponId});

  @override
  List<Object?> get props => [couponId];
}

class CouponsLoaded extends CouponState {
  final List<Map<String, dynamic>> coupons;

  const CouponsLoaded({required this.coupons});

  @override
  List<Object?> get props => [coupons];
}

class CouponError extends CouponState {
  final String error;

  const CouponError({required this.error});

  @override
  List<Object?> get props => [error];
}

class CouponValidated extends CouponState {
  final Map<String, dynamic> coupon;
  final double discountAmount;

  const CouponValidated({
    required this.coupon,
    required this.discountAmount,
  });

  @override
  List<Object?> get props => [coupon, discountAmount];
}

class CouponApplied extends CouponState {
  final Map<String, dynamic> coupon;
  final double discountAmount;
  final double totalAfterDiscount;

  const CouponApplied({
    required this.coupon,
    required this.discountAmount,
    required this.totalAfterDiscount,
  }) : super(
          appliedCoupon: coupon,
          discountAmount: discountAmount,
        );

  @override
  List<Object?> get props => [coupon, discountAmount, totalAfterDiscount, appliedCoupon];
}

class ApplicableCouponsLoaded extends CouponState {
  final List<Map<String, dynamic>> applicableCoupons;

  const ApplicableCouponsLoaded({required this.applicableCoupons});

  @override
  List<Object?> get props => [applicableCoupons];
}
