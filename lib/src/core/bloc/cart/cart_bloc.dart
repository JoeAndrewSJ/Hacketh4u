import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc({required CartRepository cartRepository})
      : _cartRepository = cartRepository,
        super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<LoadCartWithCourseData>(_onLoadCartWithCourseData);
    on<LoadCartWithFreshData>(_onLoadCartWithFreshData);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<CheckCartStatus>(_onCheckCartStatus);
    on<GetCartCount>(_onGetCartCount);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final cartItems = await _cartRepository.getUserCart();
      final cartCount = cartItems.length;
      
      // Create cart status map
      final cartStatus = <String, bool>{};
      for (final item in cartItems) {
        cartStatus[item['courseId']] = true;
      }

      emit(CartLoaded(
        cartItems: cartItems,
        cartCount: cartCount,
        cartStatus: cartStatus,
      ));
    } catch (e) {
      emit(CartError(message: 'Failed to load cart: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCartWithCourseData(LoadCartWithCourseData event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final cartItems = await _cartRepository.getCartItemsWithCourseData();
      final cartCount = cartItems.length;
      
      // Create cart status map
      final cartStatus = <String, bool>{};
      for (final item in cartItems) {
        cartStatus[item['courseId']] = true;
      }

      emit(CartLoaded(
        cartItems: cartItems,
        cartCount: cartCount,
        cartStatus: cartStatus,
      ));
    } catch (e) {
      emit(CartError(message: 'Failed to load cart with course data: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCartWithFreshData(LoadCartWithFreshData event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final cartItems = await _cartRepository.getCartItemsWithFreshData();
      final cartCount = cartItems.length;
      
      // Create cart status map
      final cartStatus = <String, bool>{};
      for (final item in cartItems) {
        cartStatus[item['courseId']] = true;
      }

      emit(CartLoaded(
        cartItems: cartItems,
        cartCount: cartCount,
        cartStatus: cartStatus,
      ));
    } catch (e) {
      emit(CartError(message: 'Failed to load cart with fresh data: ${e.toString()}'));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      final success = await _cartRepository.addToCart(event.course);
      
      if (success) {
        // Reload cart after adding with fresh data to ensure latest prices
        add(const LoadCartWithFreshData());
        emit(const CartSuccess(message: 'Course added to cart successfully'));
      } else {
        emit(const CartError(message: 'Course is already in your cart'));
      }
    } catch (e) {
      emit(CartError(message: 'Failed to add to cart: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) async {
    try {
      final success = await _cartRepository.removeFromCart(event.cartItemId);
      
      if (success) {
        // Reload cart after removing with fresh data
        add(const LoadCartWithFreshData());
        emit(const CartSuccess(message: 'Course removed from cart'));
      } else {
        emit(const CartError(message: 'Failed to remove from cart'));
      }
    } catch (e) {
      emit(CartError(message: 'Failed to remove from cart: ${e.toString()}'));
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      final success = await _cartRepository.clearCart();
      
      if (success) {
        emit(const CartLoaded(
          cartItems: [],
          cartCount: 0,
          cartStatus: {},
        ));
        emit(const CartSuccess(message: 'Cart cleared successfully'));
      } else {
        emit(const CartError(message: 'Failed to clear cart'));
      }
    } catch (e) {
      emit(CartError(message: 'Failed to clear cart: ${e.toString()}'));
    }
  }

  Future<void> _onCheckCartStatus(CheckCartStatus event, Emitter<CartState> emit) async {
    try {
      final isInCart = await _cartRepository.isInCart(event.courseId);
      
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.cartStatus);
        updatedStatus[event.courseId] = isInCart;
        
        emit(CartLoaded(
          cartItems: currentState.cartItems,
          cartCount: currentState.cartCount,
          cartStatus: updatedStatus,
        ));
      }
    } catch (e) {
      emit(CartError(message: 'Failed to check cart status: ${e.toString()}'));
    }
  }

  Future<void> _onGetCartCount(GetCartCount event, Emitter<CartState> emit) async {
    try {
      final cartCount = await _cartRepository.getCartCount();
      
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        emit(CartLoaded(
          cartItems: currentState.cartItems,
          cartCount: cartCount,
          cartStatus: currentState.cartStatus,
        ));
      }
    } catch (e) {
      emit(CartError(message: 'Failed to get cart count: ${e.toString()}'));
    }
  }
}
