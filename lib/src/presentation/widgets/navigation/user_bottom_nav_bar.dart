import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class UserBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UserBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                icon: Icons.school_rounded,
                label: 'Courses',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.chat_bubble_rounded,
                label: 'Community',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
                isProfileIcon: true,
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
    bool isProfileIcon = false,
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
                ? Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with scale and color animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? primaryColor.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isProfileIcon 
                      ? Image.asset(
                          'assets/profileicon.png',
                          width: 30,
                          height: 30,
                          color: isSelected ? primaryColor : secondaryColor,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon,
                              size: 20,
                              color: isSelected ? primaryColor : secondaryColor,
                            );
                          },
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: isSelected ? primaryColor : secondaryColor,
                        ),
                ),
              ),
              const SizedBox(height: 2),
              // Label with fade animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
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
