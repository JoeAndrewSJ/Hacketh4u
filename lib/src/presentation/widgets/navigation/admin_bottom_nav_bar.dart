import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.4) 
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.add_circle_rounded,
                label: 'Create',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with scale animation
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  size: 26,
                  color: isSelected ? primaryColor : secondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              // Label with fade and slide animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : secondaryColor,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}