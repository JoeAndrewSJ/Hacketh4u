import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/bloc/cart/cart_state.dart';
import '../../../core/bloc/coupon/coupon_bloc.dart';
import '../../../core/bloc/coupon/coupon_event.dart';
import '../../../core/bloc/coupon/coupon_state.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/cart_summary_card.dart';
import '../../widgets/cart/empty_cart_widget.dart';
import '../../widgets/common/widgets.dart';
import 'payment_screen.dart';
import 'my_purchases_screen.dart';
import 'all_courses_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _previousCartItems = [];

  @override
  void initState() {
    super.initState();
    // Clear any existing coupon state
    print('DEBUG - Cart Screen Init - Clearing coupon state');
    context.read<CouponBloc>().add(const RemoveCoupon());
    // Use fresh data to ensure latest prices are loaded
    context.read<CartBloc>().add(const LoadCartWithFreshData());
    
    // Ensure coupon state is cleared after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        final couponState = context.read<CouponBloc>().state;
        if (couponState.appliedCoupon != null) {
          print('DEBUG - Cart Screen Init - Force clearing coupon state after delay');
          context.read<CouponBloc>().add(const RemoveCoupon());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentCompletedNavigateToPurchases) {
          // Payment success navigation is now handled in payment screen
          // No need to navigate here
        } else if (state is PaymentFailedNavigateToPurchases) {
          // Navigate to My Purchases screen even after failed payment
          // Clear navigation stack so back button goes to profile
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MyPurchasesScreen(),
            ),
            (route) => route.isFirst, // Keep only the first route (main app)
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              context.read<CartBloc>().add(const LoadCartWithFreshData());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh cart with latest prices',
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.cartItems.isNotEmpty) {
                return TextButton(
                  onPressed: _clearCart,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Clear coupon when cart is modified (add/remove operations)
            context.read<CouponBloc>().add(const RemoveCoupon());
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CartLoaded) {
            if (state.cartItems.isEmpty) {
              // Clear coupon if cart is empty
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final couponState = context.read<CouponBloc>().state;
                if (couponState.appliedCoupon != null) {
                  print('DEBUG - Cart Screen - Clearing coupon because cart is empty');
                  context.read<CouponBloc>().add(const RemoveCoupon());
                }
              });
              return EmptyCartWidget(
                isDark: isDark,
                onBrowseCourses: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCoursesScreen(),
                    ),
                  );
                },
              );
            } else {
              // Check if cart items have changed and clear coupon if needed
              if (_previousCartItems.length != state.cartItems.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final couponState = context.read<CouponBloc>().state;
                  if (couponState.appliedCoupon != null) {
                    print('DEBUG - Cart Screen - Clearing coupon because cart items changed');
                    context.read<CouponBloc>().add(const RemoveCoupon());
                  }
                });
              }
              _previousCartItems = List.from(state.cartItems);
              return _buildCartContent(state.cartItems, isDark);
            }
          } else if (state is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cart',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CartBloc>().add(const LoadCart());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded && state.cartItems.isNotEmpty) {
            return _buildCheckoutBar(state.cartItems, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    ),
    );
  }

  Widget _buildCartContent(List<Map<String, dynamic>> cartItems, bool isDark) {
    return Column(
      children: [
        // Cart Summary
        BlocBuilder<CouponBloc, CouponState>(
          builder: (context, couponState) {
            print('DEBUG - Cart Summary - Coupon State: ${couponState.runtimeType}');
            print('DEBUG - Cart Summary - Discount Amount: ${couponState.discountAmount}');
            print('DEBUG - Cart Summary - Applied Coupon: ${couponState.appliedCoupon}');
            print('DEBUG - Cart Summary - Is Loading: ${couponState.isLoading}');
            return CartSummaryCard(
              cartItems: cartItems,
              isDark: isDark,
              couponDiscount: couponState.discountAmount,
              appliedCoupon: couponState.appliedCoupon,
              onRemoveCoupon: () {
                print('DEBUG - Cart Screen - Removing coupon');
                context.read<CouponBloc>().add(const RemoveCoupon());
                _couponController.clear();
                print('DEBUG - Cart Screen - Coupon controller cleared');
              },
            );
          },
        ),

        // Coupon Input Section
        _buildCouponSection(cartItems, isDark),

        // Cart Items
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Force refresh with latest data
              context.read<CartBloc>().add(const LoadCartWithFreshData());
              // Wait a bit for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                print('Cart Item----------------->: $item');
                return CartItemCard(
                  cartItem: item,
                  isDark: isDark,
                  onRemove: () => _removeFromCart(item['id']),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(List<Map<String, dynamic>> cartItems, bool isDark) {
    final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + (item['price'] as double? ?? 0.0));

    return BlocBuilder<CouponBloc, CouponState>(
      builder: (context, couponState) {
        final couponDiscount = couponState.discountAmount;
        final finalTotal = totalPrice - couponDiscount;
        
        return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (couponDiscount > 0) ...[
                      Text(
                        '₹${totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '₹${finalTotal.toStringAsFixed(0)}',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Checkout Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _proceedToCheckout,
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  void _removeFromCart(String cartItemId) {
    context.read<CartBloc>().add(RemoveFromCart(cartItemId: cartItemId));
    // Clear coupon when item is removed
    context.read<CouponBloc>().add(const RemoveCoupon());
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(const ClearCart());
              // Clear coupon when cart is cleared
              context.read<CouponBloc>().add(const RemoveCoupon());
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    // Get current cart state
    final cartState = context.read<CartBloc>().state;
    final couponState = context.read<CouponBloc>().state;
    
    if (cartState is CartLoaded && cartState.cartItems.isNotEmpty) {
      // Calculate totals
      final totalAmount = cartState.cartItems.fold<double>(
        0, (sum, item) => sum + (item['price'] as double? ?? 0.0)
      );
      final discountAmount = couponState.discountAmount;
      final finalAmount = totalAmount - discountAmount;
      
      // Navigate to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            cartItems: cartState.cartItems,
            totalAmount: totalAmount,
            discountAmount: discountAmount,
            finalAmount: finalAmount,
            appliedCoupon: couponState.appliedCoupon,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCouponSection(List<Map<String, dynamic>> cartItems, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: AppTheme.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Apply Coupon',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Coupon Input and Apply Button
          BlocConsumer<CouponBloc, CouponState>(
            listener: (context, state) {
              if (state is CouponError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is CouponApplied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coupon applied! You saved ₹${state.discountAmount.toStringAsFixed(0)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            builder: (context, state) {
              print('DEBUG - Coupon Input - State: ${state.runtimeType}, Applied Coupon: ${state.appliedCoupon}, Discount: ${state.discountAmount}');
              return Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Coupon Code',
                      hint: state.appliedCoupon != null ? 'Coupon already applied' : 'Enter coupon code',
                      controller: _couponController,
                      prefixIcon: const Icon(Icons.confirmation_number),
                      enabled: state.appliedCoupon == null,
                      onSubmitted: (value) => _applyCoupon(cartItems),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (state.isLoading || state.appliedCoupon != null) ? null : () => _applyCoupon(cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.appliedCoupon != null ? Colors.grey : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(state.appliedCoupon != null ? 'Applied' : 'Apply'),
                  ),
                ],
              );
            },
          ),
          
        ],
      ),
    );
  }

  final TextEditingController _couponController = TextEditingController();

  void _applyCoupon(List<Map<String, dynamic>> cartItems) {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final courseIds = cartItems.map((item) => item['courseId'] as String).toList();
    context.read<CouponBloc>().add(ApplyCoupon(
      couponCode: couponCode,
      cartItems: cartItems,
    ));
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}
