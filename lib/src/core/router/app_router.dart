import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/bloc.dart';
import '../bloc/course_access/course_access_bloc.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/user_progress/user_progress_bloc.dart';
import '../bloc/user_profile/user_profile_bloc.dart';
import '../bloc/community/community_bloc.dart';
import '../bloc/banner/banner_bloc.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/home/admin_home_screen.dart';
import '../../presentation/screens/home/user_home_screen.dart';
import '../../presentation/screens/user/user_main_screen.dart';
import '../../presentation/screens/user/course_details_screen.dart';
import '../../presentation/screens/user/cart_screen.dart';
import '../di/service_locator.dart';
import '../theme/app_theme.dart';
import '../../presentation/widgets/common/connectivity_snackbar.dart';

// Global navigator key for programmatic navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => sl<ThemeBloc>()..add(ThemeStarted()),
        ),
        BlocProvider<ConnectivityBloc>(
          create: (context) => ConnectivityBloc(
            connectivityRepository: sl(),
          )..add(ConnectivityStarted()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(AuthStarted()),
        ),
        BlocProvider<MentorBloc>(
          create: (context) => sl<MentorBloc>(),
        ),
        BlocProvider<CourseBloc>(
          create: (context) => sl<CourseBloc>(),
        ),
        BlocProvider<QuizBloc>(
          create: (context) => sl<QuizBloc>(),
        ),
        BlocProvider<CouponBloc>(
          create: (context) => CouponBloc(firestore: sl<FirebaseFirestore>()),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(cartRepository: sl<CartRepository>()),
        ),
        BlocProvider<PaymentBloc>(
          create: (context) => PaymentBloc(paymentRepository: sl<PaymentRepository>()),
        ),
        BlocProvider<CourseAccessBloc>(
          create: (context) => sl<CourseAccessBloc>(),
        ),
        BlocProvider<ReviewBloc>(
          create: (context) => sl<ReviewBloc>(),
        ),
        BlocProvider<UserProgressBloc>(
          create: (context) => sl<UserProgressBloc>(),
        ),
        BlocProvider<UserProfileBloc>(
          create: (context) => sl<UserProfileBloc>(),
        ),
        BlocProvider<CommunityBloc>(
          create: (context) => sl<CommunityBloc>(),
        ),
        BlocProvider<BannerBloc>(
          create: (context) => sl<BannerBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Hackethos4U',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              // Clamp text scale factor to prevent system font size from breaking UI
              // Allows scaling from 0.8x to 1.3x (accessibility-friendly but prevents extreme cases)
              final mediaQueryData = MediaQuery.of(context);
              final constrainedTextScaleFactor = mediaQueryData.textScaleFactor.clamp(0.8, 1.3);

              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaleFactor: constrainedTextScaleFactor,
                ),
                child: child!,
              );
            },
            home: const ConnectivitySnackbar(
              child: AppNavigator(),
            ),
          );
        },
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _showSplash = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Show splash for minimum duration
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always show splash screen first
    if (_showSplash) {
      return const SplashScreen();
    }

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        // Debug logging
        print('AuthState changed: isLoading=${authState.isLoading}, isAuthenticated=${authState.isAuthenticated}, userRole=${authState.userRole}');

        // Handle auth state changes that require navigation
        if (!authState.isLoading) {
          // Handle logout: Navigate back to root when user becomes unauthenticated
          if (_isAuthenticated && !authState.isAuthenticated) {
            print('User logged out, popping to root');
            // Pop all routes to go back to the root (AppNavigator)
            Navigator.of(context).popUntil((route) => route.isFirst);
          }

          // Handle login: Navigate back to root when user becomes authenticated
          if (!_isAuthenticated && authState.isAuthenticated && authState.userRole != null) {
            print('User logged in, popping to root');
            // Pop all routes to go back to the root (AppNavigator) which will show the correct home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }

        // Update local state to track authentication changes
        _isAuthenticated = authState.isAuthenticated;
      },
      builder: (context, authState) {
        // Debug logging
        print('AuthState: isLoading=${authState.isLoading}, isAuthenticated=${authState.isAuthenticated}, userRole=${authState.userRole}');

        // If loading, show splash while determining auth state
        if (authState.isLoading) {
          print('Auth still loading, showing SplashScreen');
          return const SplashScreen();
        }

        // Navigate based on authentication state
        if (authState.isAuthenticated && authState.userRole != null) {
          // Navigate based on user role
          switch (authState.userRole!) {
            case UserRole.admin:
              print('Navigating to AdminHomeScreen');
              return const AdminHomeScreen();
            case UserRole.user:
              print('Navigating to UserMainScreen');
              return const UserMainScreen();
          }
        } else {
          // User is not authenticated or role not determined, show login screen
          print('Navigating to LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}
