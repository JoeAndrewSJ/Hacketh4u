import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_create_screen.dart';
import '../../screens/admin/admin_profile_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/admin/coupon_management_screen.dart';
import '../../screens/admin/community_chat_screen.dart';
import '../../screens/admin/admin_reviews_management_screen.dart';
import '../../screens/admin/ads_banner_screen.dart';
import '../../screens/admin/stats_screen.dart';
import '../../screens/admin/all_courses_screen.dart';
import '../../screens/admin/all_users_screen.dart' as users_screen;
import '../../screens/admin/mentors_list_screen.dart';

/// Universal admin navigation menu that can be accessed from any admin screen
/// Provides quick access to all major admin features with a single tap
class AdminNavigationMenu extends StatelessWidget {
  final String? currentRoute;

  const AdminNavigationMenu({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Navigation Menu',
      onPressed: () => _showNavigationMenu(context),
    );
  }

  void _showNavigationMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[600]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Menu Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryLight,
                                AppTheme.primaryLight.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quick Navigation',
                          style: AppTextStyles.h3.copyWith(
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuSection(
                      context,
                      'Main',
                      [
                        _MenuItem(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          subtitle: 'Dashboard & course actions',
                          color: Colors.blue,
                          route: '/admin/home',
                          screen: const AdminHomeScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.analytics,
                          title: 'Analytics',
                          subtitle: 'Stats & insights',
                          color: Colors.indigo,
                          route: '/admin/stats',
                          screen: const StatsScreen(),
                        ),
                      ],
                      isDark,
                    ),

                    _buildMenuSection(
                      context,
                      'Content Management',
                      [
                        _MenuItem(
                          icon: Icons.library_books,
                          title: 'All Courses',
                          subtitle: 'Manage course library',
                          color: Colors.purple,
                          route: '/admin/courses',
                          screen: const AllCoursesScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.rate_review,
                          title: 'Reviews',
                          subtitle: 'Manage course reviews',
                          color: Colors.teal,
                          route: '/admin/reviews',
                          screen: const AdminReviewsManagementScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.campaign,
                          title: 'Ads Banners',
                          subtitle: 'Promotional banners',
                          color: Colors.orange,
                          route: '/admin/banners',
                          screen: const AdsBannerScreen(),
                        ),
                      ],
                      isDark,
                    ),

                    _buildMenuSection(
                      context,
                      'User Management',
                      [
                        _MenuItem(
                          icon: Icons.people,
                          title: 'All Users',
                          subtitle: 'User accounts & permissions',
                          color: Colors.green,
                          route: '/admin/users',
                          screen: const users_screen.AllUsersScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.school,
                          title: 'Mentors',
                          subtitle: 'Instructor management',
                          color: Colors.deepPurple,
                          route: '/admin/mentors',
                          screen: const MentorsListScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.chat,
                          title: 'Community',
                          subtitle: 'Workspaces & groups',
                          color: Colors.green[700]!,
                          route: '/admin/community',
                          screen: const CommunityChatScreen(),
                        ),
                      ],
                      isDark,
                    ),

                    _buildMenuSection(
                      context,
                      'Settings & Tools',
                      [
                        _MenuItem(
                          icon: Icons.local_offer,
                          title: 'Coupons',
                          subtitle: 'Discount management',
                          color: Colors.purple[700]!,
                          route: '/admin/coupons',
                          screen: const CouponManagementScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'System configuration',
                          color: Colors.blueGrey,
                          route: '/admin/settings',
                          screen: const AdminSettingsScreen(),
                        ),
                        _MenuItem(
                          icon: Icons.person,
                          title: 'Profile',
                          subtitle: 'Admin account settings',
                          color: Colors.blue[700]!,
                          route: '/admin/profile',
                          screen: const AdminProfileScreen(),
                        ),
                      ],
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(context, item, isDark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    _MenuItem item,
    bool isDark,
  ) {
    final isCurrentRoute = currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentRoute
            ? item.color.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentRoute
            ? Border.all(
                color: item.color.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close the menu

            // Navigate with replacement to avoid stack buildup
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => item.screen),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                          fontWeight: isCurrentRoute
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current indicator or arrow
                if (isCurrentRoute)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Private class to hold menu item data
class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  final Widget screen;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
    required this.screen,
  });
}
