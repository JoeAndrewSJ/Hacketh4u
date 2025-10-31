import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/bloc/cart/cart_state.dart';
import '../common/widgets.dart';
import '../../screens/user/cart_screen.dart';

class AddToCartButton extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final VoidCallback? onSuccess;
  final bool hasCourseAccess;

  const AddToCartButton({
    super.key,
    required this.course,
    required this.isDark,
    this.onSuccess,
    this.hasCourseAccess = false,
  });

  @override
  Widget build(BuildContext context) {
    // If user has course access, show access status instead of cart button
    if (hasCourseAccess) {
      return CustomButton(
        text: 'Course Purchased',
        onPressed: null, // Disabled button
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }

    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
            ),
          );
          onSuccess?.call();
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
        // Check if course is in cart
        bool isInCart = false;
        if (state is CartLoaded) {
          isInCart = state.cartStatus[course['id']] ?? false;
        }

        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            final isLoading = cartState is CartLoading;

            if (isInCart) {
              return CustomButton(
                text: 'In Cart',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
              );
            }

            return CustomButton(
              text: 'Add to Cart',
              onPressed: isLoading ? null : () {
                context.read<CartBloc>().add(AddToCart(course: course));
              },
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              icon: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add_shopping_cart, color: Colors.white),
            );
          },
        );
      },
    );
  }
}
