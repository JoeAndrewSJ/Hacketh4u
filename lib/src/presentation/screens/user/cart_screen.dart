import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/bloc/cart/cart_state.dart';
import '../../../core/bloc/coupon/coupon_bloc.dart';
import '../../../core/bloc/coupon/coupon_event.dart';
import '../../../core/bloc/coupon/coupon_state.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/cart_summary_card.dart';
import '../../widgets/cart/empty_cart_widget.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/payment/user_details_bottom_sheet.dart';
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
    context.read<CouponBloc>().add(const RemoveCoupon());
    context.read<CartBloc>().add(const LoadCartWithFreshData());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        final couponState = context.read<CouponBloc>().state;
        if (couponState.appliedCoupon != null) {
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
        title: Text(
          'Your Cart',
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        centerTitle: true,
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
                    style: AppTextStyles.bodyMedium.copyWith(
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
            CustomSnackBar.showSuccess(context, state.message);
            // Clear coupon when cart is modified (add/remove operations)
            context.read<CouponBloc>().add(const RemoveCoupon());
          } else if (state is CartError) {
            CustomSnackBar.showError(context, state.message);
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
              if (_previousCartItems.length != state.cartItems.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final couponState = context.read<CouponBloc>().state;
                  if (couponState.appliedCoupon != null) {
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
            return CartSummaryCard(
              cartItems: cartItems,
              isDark: isDark,
              couponDiscount: couponState.discountAmount,
              appliedCoupon: couponState.appliedCoupon,
              onRemoveCoupon: () {
                context.read<CouponBloc>().add(const RemoveCoupon());
                _couponController.clear();
              },
            );
          },
        ),

        // Coupon Input Section
        _buildCouponSection(cartItems, isDark),

        // Cart Items Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_rounded,
                color: AppTheme.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cart Items (${cartItems.length})',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        // Cart Items
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<CartBloc>().add(const LoadCartWithFreshData());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return CartItemCard(
                  cartItem: item,
                  isDark: isDark,
                  onRemove: () => _removeFromCart(item['id'] ?? ''),
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

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
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
                        'Total Amount',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (couponDiscount > 0) ...[
                            Text(
                              '₹${totalPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '₹${finalTotal.toStringAsFixed(0)}',
                            style: AppTextStyles.h2.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkout Button
                ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Proceed to Pay',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
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
            child: Text('Clear', style: AppTextStyles.bodyMedium.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout() async {
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

      // Validate user details before proceeding
      await _validateUserDetailsAndProceed(
        cartItems: cartState.cartItems,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        finalAmount: finalAmount,
        appliedCoupon: couponState.appliedCoupon,
      );
    } else {
      CustomSnackBar.showError(context, 'Your cart is empty!');
    }
  }

  Future<void> _validateUserDetailsAndProceed({
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required double discountAmount,
    required double finalAmount,
    required Map<String, dynamic>? appliedCoupon,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading
        CustomSnackBar.showError(context, 'Please login to continue');
        return;
      }

      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        Navigator.of(context).pop(); // Close loading
        CustomSnackBar.showError(context, 'User not found. Please login again.');
        return;
      }

      final user = UserModel.fromMap(userDoc.data()!, userId);
      Navigator.of(context).pop(); // Close loading

      // Check if user data is complete
      final needsName = user.name.isEmpty;
      final needsEmail = user.email.isEmpty;
      final needsPhone = user.phoneNumber == null || user.phoneNumber!.isEmpty;

      if (needsName || needsEmail || needsPhone) {
        // Show bottom sheet to collect missing data
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => UserDetailsBottomSheet(
            user: user,
            onCompleted: () {
              // After updating user details, proceed to payment
              _navigateToPayment(
                cartItems: cartItems,
                totalAmount: totalAmount,
                discountAmount: discountAmount,
                finalAmount: finalAmount,
                appliedCoupon: appliedCoupon,
              );
            },
          ),
        );
      } else {
        // All data is present, proceed directly
        _navigateToPayment(
          cartItems: cartItems,
          totalAmount: totalAmount,
          discountAmount: discountAmount,
          finalAmount: finalAmount,
          appliedCoupon: appliedCoupon,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading if still open
      CustomSnackBar.showError(context, 'Error: ${e.toString()}');
    }
  }

  void _navigateToPayment({
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required double discountAmount,
    required double finalAmount,
    required Map<String, dynamic>? appliedCoupon,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          cartItems: cartItems,
          totalAmount: totalAmount,
          discountAmount: discountAmount,
          finalAmount: finalAmount,
          appliedCoupon: appliedCoupon,
        ),
      ),
    );
  }

  Widget _buildCouponSection(List<Map<String, dynamic>> cartItems, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: AppTheme.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Have a coupon?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coupon Input and Apply Button
          BlocConsumer<CouponBloc, CouponState>(
            listener: (context, state) {
              if (state is CouponError) {
                CustomSnackBar.showError(context, state.error);
              } else if (state is CouponApplied) {
                CustomSnackBar.showSuccess(context, 'Saved ₹${state.discountAmount.toStringAsFixed(0)} with this coupon!');
              }
            },
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hint: state.appliedCoupon != null ? 'Coupon applied' : 'Enter code',
                      controller: _couponController,
                      prefixIcon: const Icon(Icons.confirmation_number_rounded, size: 20),
                      enabled: state.appliedCoupon == null,
                      onSubmitted: (value) => _applyCoupon(cartItems),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (state.isLoading || state.appliedCoupon != null) ? null : () => _applyCoupon(cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.appliedCoupon != null ? Colors.grey[400] : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            state.appliedCoupon != null ? 'Applied' : 'Apply',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
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
      CustomSnackBar.showWarning(context, 'Please enter a coupon code');
      return;
    }

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
