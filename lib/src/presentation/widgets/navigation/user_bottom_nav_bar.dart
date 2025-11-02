import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/app_settings/app_settings_bloc.dart';
import '../../../core/bloc/app_settings/app_settings_state.dart';
import '../../../core/di/service_locator.dart';

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

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      bloc: sl<AppSettingsBloc>(),
      builder: (context, state) {
        // Determine if community is enabled
        bool isCommunityEnabled = true; // Default to true
        if (state is AppSettingsLoaded) {
          isCommunityEnabled = state.settings.isCommunityEnabled;
        } else if (state is AppSettingsError && state.lastKnownSettings != null) {
          isCommunityEnabled = state.lastKnownSettings!.isCommunityEnabled;
        }

        // Build navigation items list dynamically
        final navItems = <Widget>[
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
          if (isCommunityEnabled)
            _buildNavItem(
              context: context,
              index: 2,
              icon: Icons.chat_bubble_rounded,
              label: 'Community',
              isDark: isDark,
            ),
          _buildNavItem(
            context: context,
            index: isCommunityEnabled ? 3 : 2,
            icon: Icons.person_rounded,
            label: 'Profile',
            isDark: isDark,
          ),
        ];

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
                children: navItems,
              ),
            ),
          ),
        );
      },
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
              Icon(
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
