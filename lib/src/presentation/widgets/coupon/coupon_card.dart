import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = coupon['isActive'] ?? true;
    final validUntil = coupon['validUntil'];
    final isValid = _isValidCoupon(validUntil, isActive);
    final discountPercentage = coupon['discountPercentage'] ?? 0;
    final courseTitle = coupon['courseTitle'] ?? 'All Courses';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isValid 
                ? Border.all(color: Colors.green, width: 2)
                : Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Coupon Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isValid 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: isValid ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Coupon Code and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                coupon['code'] ?? 'Unknown Code',
                                style: AppTextStyles.h3.copyWith(
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isValid ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isValid ? 'ACTIVE' : 'INACTIVE',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          courseTitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Coupon'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Coupon',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Coupon Details
              Row(
                children: [
                  _buildDetailChip(
                    icon: Icons.percent,
                    label: '$discountPercentage% OFF',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    icon: Icons.schedule,
                    label: _formatValidUntil(validUntil),
                    color: isValid ? Colors.green : Colors.red,
                    isDark: isDark,
                  ),
                  const Spacer(),
                  if (coupon['createdAt'] != null)
                    Text(
                      _formatDate(coupon['createdAt']),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidCoupon(dynamic validUntil, bool isActive) {
    if (!isActive) return false;
    if (validUntil == null) return true;
    
    try {
      final validDate = validUntil.toDate();
      return validDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _formatValidUntil(dynamic validUntil) {
    if (validUntil == null) return 'No expiry';
    
    try {
      final validDate = validUntil.toDate();
      final now = DateTime.now();
      final difference = validDate.difference(now);
      
      if (difference.inDays < 0) {
        return 'Expired';
      } else if (difference.inDays == 0) {
        return 'Expires today';
      } else if (difference.inDays == 1) {
        return 'Expires tomorrow';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days left';
      } else {
        return '${validDate.day}/${validDate.month}/${validDate.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
