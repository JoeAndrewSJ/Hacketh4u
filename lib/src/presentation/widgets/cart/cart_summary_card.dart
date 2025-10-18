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

  double _getDiscountPercentage(Map<String, dynamic>? coupon) {
    if (coupon == null) return 0.0;
    final discountPercentageValue = coupon['discountPercentage'];
    if (discountPercentageValue is double) {
      return discountPercentageValue;
    } else if (discountPercentageValue is int) {
      return discountPercentageValue.toDouble();
    } else if (discountPercentageValue is num) {
      return discountPercentageValue.toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + (item['price'] as double? ?? 0.0));
    final totalOriginalPrice = cartItems.fold<double>(0, (sum, item) => sum + (item['originalPrice'] as double? ?? 0.0));
    final totalSavings = totalOriginalPrice - totalPrice;
    final couponDiscountAmount = couponDiscount ?? 0.0;
    final finalTotal = totalPrice - couponDiscountAmount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.surfaceDark, AppTheme.surfaceDark]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primaryLight,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),

          // Items count and subtotal
          _buildSummaryRow(
            'Subtotal (${cartItems.length} ${cartItems.length > 1 ? 'items' : 'item'})',
            '₹${totalPrice.toStringAsFixed(0)}',
            isRegular: true,
          ),

          // Course discount savings
          if (totalSavings > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              'Course discount',
              '-₹${totalSavings.toStringAsFixed(0)}',
              color: Colors.green[600]!,
            ),
          ],

          // Coupon discount
          if (couponDiscountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              'Coupon (${appliedCoupon?['code'] ?? ''})',
              '-₹${couponDiscountAmount.toStringAsFixed(0)}',
              color: AppTheme.primaryLight,
            ),
          ],

          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '₹${finalTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),

          // Applied Coupon Chip
          if (appliedCoupon != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appliedCoupon?['code'] ?? 'COUPON'}',
                          style: TextStyle(
                            color: Colors.green[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${_getDiscountPercentage(appliedCoupon).toInt()}% discount applied',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onRemoveCoupon,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.red[600],
                        size: 18,
                      ),
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

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isRegular = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            fontSize: isRegular ? 14 : 13,
            fontWeight: isRegular ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
            fontSize: isRegular ? 14 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
