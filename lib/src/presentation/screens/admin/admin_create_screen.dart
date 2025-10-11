import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_settings_screen.dart';
import 'coupon_management_screen.dart';
import 'community_chat_screen.dart';
import 'ads_banner_screen.dart';

class AdminCreateScreen extends StatefulWidget {
  const AdminCreateScreen({super.key});

  @override
  State<AdminCreateScreen> createState() => _AdminCreateScreenState();
}

class _AdminCreateScreenState extends State<AdminCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'General',
    'Security',
    'User Management',
    'System',
    'Reports',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildSettingsCard(context, isDark),
                  _buildCouponCard(context, isDark),
                  _buildCommunityCard(context, isDark),
                  _buildAdsBannerCard(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminSettingsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.grey[800]!, Colors.grey[700]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                size: 48,
                color: isDark ? Colors.blue[300] : Colors.blue[600],
              ),
              const SizedBox(height: 12),
              Text(
                'Settings',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage users and system settings',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CouponManagementScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.purple[800]!, Colors.purple[700]!]
                : [Colors.purple[50]!, Colors.purple[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer,
                size: 48,
                color: isDark ? Colors.purple[300] : Colors.purple[600],
              ),
              const SizedBox(height: 12),
              Text(
                'Coupons',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create and manage discount coupons',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityChatScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.green[800]!, Colors.green[700]!]
                : [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat,
                size: 48,
                color: isDark ? Colors.green[300] : Colors.green[600],
              ),
              const SizedBox(height: 12),
              Text(
                'Community',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create community chat',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsBannerCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdsBannerScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.orange[800]!, Colors.orange[700]!]
                : [Colors.orange[50]!, Colors.orange[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign,
                size: 48,
                color: isDark ? Colors.orange[300] : Colors.orange[600],
              ),
              const SizedBox(height: 12),
              Text(
                'Ads Banners',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create and manage advertisement banners',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

}