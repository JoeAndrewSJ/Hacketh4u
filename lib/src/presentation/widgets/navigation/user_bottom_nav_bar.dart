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
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
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
    final inactiveColor = isDark
        ? AppTheme.textSecondaryDark.withOpacity(0.6)
        : AppTheme.textSecondaryLight.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: primaryColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active indicator bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),

              // Icon
              isProfileIcon
                  ? Image.asset(
                      'assets/profileicon.png',
                      width: 24,
                      height: 24,
                      color: isSelected ? primaryColor : inactiveColor,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          icon,
                          size: 24,
                          color: isSelected ? primaryColor : inactiveColor,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      size: 24,
                      color: isSelected ? primaryColor : inactiveColor,
                    ),
              const SizedBox(height: 2),

              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : inactiveColor,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
