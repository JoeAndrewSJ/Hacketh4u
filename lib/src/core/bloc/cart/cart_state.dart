import 'package:equatable/equatable.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<Map<String, dynamic>> cartItems;
  final int cartCount;
  final Map<String, bool> cartStatus; // courseId -> isInCart

  const CartLoaded({
    required this.cartItems,
    required this.cartCount,
    this.cartStatus = const {},
  });

  @override
  List<Object?> get props => [cartItems, cartCount, cartStatus];
}

class CartError extends CartState {
  final String message;

  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CartSuccess extends CartState {
  final String message;

  const CartSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
