import 'package:flutter/material.dart';
import '../../widgets/navigation/admin_bottom_nav_bar.dart';
import '../admin/admin_home_screen.dart' as admin_home;
import '../admin/admin_create_screen.dart';
import '../admin/admin_profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final int initialIndex;

  const AdminHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const AdminCreateScreen(),          // Index 0: Home - Shows admin tools hub (Settings, Coupons, Community, etc.)
    const admin_home.AdminHomeScreen(), // Index 1: Create - Shows create actions (Create Course, Create Mentor, All Courses)
    const AdminProfileScreen(),         // Index 2: Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove parent AppBar - let child screens handle their own AppBars
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

}
