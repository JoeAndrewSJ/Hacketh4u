import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CartSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final bool isDark;
  final double? couponDiscount;
  final Map<String, dynamic>? appliedCoupon;
  final VoidCallback? onRemoveCoupon;

  const CartSummaryCard({
    super.key,
    required this.cartItems,
    required this.isDark,
    this.couponDiscount,
    this.appliedCoupon,
    this.onRemoveCoupon,
  });

  // Helper method to safely extract discount percentage
  double _getDiscountPercentage(Map<String, dynamic> coupon) {
    final discountPercentageValue = coupon['discountPercentage'];
    print('DEBUG - Helper - Discount Percentage Value: $discountPercentageValue (type: ${discountPercentageValue.runtimeType})');
    if (discountPercentageValue is double) {
      print('DEBUG - Helper - Returning double: $discountPercentageValue');
      return discountPercentageValue;
    } else if (discountPercentageValue is int) {
      print('DEBUG - Helper - Converting int to double: ${discountPercentageValue.toDouble()}');
      return discountPercentageValue.toDouble();
    } else if (discountPercentageValue is num) {
      print('DEBUG - Helper - Converting num to double: ${discountPercentageValue.toDouble()}');
      return discountPercentageValue.toDouble();
    }
    print('DEBUG - Helper - Returning default 0.0');
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + (item['price'] as double? ?? 0.0));
    final totalOriginalPrice = cartItems.fold<double>(0, (sum, item) => sum + (item['originalPrice'] as double? ?? 0.0));
    final totalSavings = totalOriginalPrice - totalPrice;
    final couponDiscountAmount = couponDiscount ?? 0.0;
    final finalTotal = totalPrice - couponDiscountAmount;
    
    print('DEBUG - CART SUMMARY MATH CHECK:');
    print('DEBUG - Cart Items Count: ${cartItems.length}');
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      print('DEBUG - Item $i: ${item['title']} - Price: ${item['price']} (type: ${item['price'].runtimeType}) - Original: ${item['originalPrice']} (type: ${item['originalPrice'].runtimeType}) - CourseId: ${item['courseId']}');
    }
    print('DEBUG - Total Price: $totalPrice');
    print('DEBUG - Total Original Price: $totalOriginalPrice');
    print('DEBUG - Total Savings (Original - Price): $totalSavings');
    print('DEBUG - Coupon Discount Amount: $couponDiscountAmount');
    print('DEBUG - Final Total (Price - Coupon): $finalTotal');
    print('DEBUG - Applied Coupon: $appliedCoupon');
    if (appliedCoupon != null) {
      print('DEBUG - Cart Summary Card - Applied Coupon Keys: ${appliedCoupon!.keys.toList()}');
      print('DEBUG - Cart Summary Card - Discount Percentage Raw: ${appliedCoupon!['discountPercentage']} (type: ${appliedCoupon!['discountPercentage'].runtimeType})');
      print('DEBUG - Cart Summary Card - Helper Result: ${_getDiscountPercentage(appliedCoupon!)}');
    }

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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cartItems.length} course${cartItems.length > 1 ? 's' : ''}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (couponDiscountAmount > 0) ...[
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
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (totalSavings > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You save',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${totalSavings.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (couponDiscountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coupon Discount (${appliedCoupon?['code'] ?? ''} - ${_getDiscountPercentage(appliedCoupon ?? {}).toInt()}%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-₹${couponDiscountAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          
          // Applied Coupon Chip
          if (appliedCoupon != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${appliedCoupon!['code']} - ${_getDiscountPercentage(appliedCoupon!).toInt()}% off',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onRemoveCoupon,
                    child: Icon(
                      Icons.close,
                      color: Colors.red[600],
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
