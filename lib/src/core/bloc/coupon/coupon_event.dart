import 'package:equatable/equatable.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();

  @override
  List<Object?> get props => [];
}

class CreateCoupon extends CouponEvent {
  final Map<String, dynamic> couponData;

  const CreateCoupon({required this.couponData});

  @override
  List<Object?> get props => [couponData];
}

class UpdateCoupon extends CouponEvent {
  final String couponId;
  final Map<String, dynamic> couponData;

  const UpdateCoupon({
    required this.couponId,
    required this.couponData,
  });

  @override
  List<Object?> get props => [couponId, couponData];
}

class DeleteCoupon extends CouponEvent {
  final String couponId;

  const DeleteCoupon({required this.couponId});

  @override
  List<Object?> get props => [couponId];
}

class LoadCoupons extends CouponEvent {
  const LoadCoupons();
}

class ValidateCoupon extends CouponEvent {
  final String couponCode;
  final List<String> courseIds;

  const ValidateCoupon({
    required this.couponCode,
    required this.courseIds,
  });

  @override
  List<Object?> get props => [couponCode, courseIds];
}

class ApplyCoupon extends CouponEvent {
  final String couponCode;
  final List<Map<String, dynamic>> cartItems;

  const ApplyCoupon({
    required this.couponCode,
    required this.cartItems,
  });

  @override
  List<Object?> get props => [couponCode, cartItems];
}

class RemoveCoupon extends CouponEvent {
  const RemoveCoupon();
}
