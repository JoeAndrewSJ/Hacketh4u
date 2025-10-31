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
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 50,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/emptycart.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.textSecondaryDark.withOpacity(0.1) : AppTheme.textSecondaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 60,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    );
                  },
                ),
              ),
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
