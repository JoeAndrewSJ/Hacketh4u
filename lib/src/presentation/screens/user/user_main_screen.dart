import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/navigation/user_bottom_nav_bar.dart';
import '../../../core/bloc/app_settings/app_settings_bloc.dart';
import '../../../core/bloc/app_settings/app_settings_state.dart';
import '../../../core/di/service_locator.dart';
import 'user_home_screen.dart';
import 'my_courses_screen.dart';
import 'community_chat_screen.dart';
import 'user_profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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

        // Build screens list dynamically based on community setting
        final screens = <Widget>[
          const UserHomeScreen(),
          const MyCoursesScreen(),
          if (isCommunityEnabled) const CommunityChatScreen(),
          const UserProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: UserBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
