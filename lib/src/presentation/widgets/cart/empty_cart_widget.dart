import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../common/widgets.dart';

class EmptyCartWidget extends StatelessWidget {
  final VoidCallback? onBrowseCourses;
  final bool isDark;

  const EmptyCartWidget({
    super.key,
    this.onBrowseCourses,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add some courses to get started!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onBrowseCourses != null)
              CustomButton(
                text: 'Browse Courses',
                onPressed: onBrowseCourses!,
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.explore, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
