import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  const LoadCart();
}

class AddToCart extends CartEvent {
  final Map<String, dynamic> course;

  const AddToCart({required this.course});

  @override
  List<Object?> get props => [course];
}

class RemoveFromCart extends CartEvent {
  final String cartItemId;

  const RemoveFromCart({required this.cartItemId});

  @override
  List<Object?> get props => [cartItemId];
}

class ClearCart extends CartEvent {
  const ClearCart();
}

class CheckCartStatus extends CartEvent {
  final String courseId;

  const CheckCartStatus({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class GetCartCount extends CartEvent {
  const GetCartCount();
}

class LoadCartWithCourseData extends CartEvent {
  const LoadCartWithCourseData();
}

class LoadCartWithFreshData extends CartEvent {
  const LoadCartWithFreshData();
}