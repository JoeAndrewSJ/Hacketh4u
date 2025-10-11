import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'all_users_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsOption(
                    context: context,
                    isDark: isDark,
                    icon: Icons.people,
                    title: 'All Users',
                    subtitle: 'Manage user accounts and permissions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllUsersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsOption(
                    context: context,
                    isDark: isDark,
                    icon: Icons.security,
                    title: 'Security Settings',
                    subtitle: 'Configure security policies',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Security settings coming soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsOption(
                    context: context,
                    isDark: isDark,
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    subtitle: 'Manage push notifications',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification settings coming soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsOption(
                    context: context,
                    isDark: isDark,
                    icon: Icons.backup,
                    title: 'Backup & Restore',
                    subtitle: 'Manage data backup and restore',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup settings coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.blue[800] : Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.blue[200] : Colors.blue[600],
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
