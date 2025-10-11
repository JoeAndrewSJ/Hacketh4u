import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/bloc.dart';
import '../bloc/course_access/course_access_bloc.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/user_progress/user_progress_bloc.dart';
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
          create: (context) => QuizBloc(firestore: sl<FirebaseFirestore>()),
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
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Hackethos4U',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Debug logging
        print('AuthState: isLoading=${authState.isLoading}, isAuthenticated=${authState.isAuthenticated}, userRole=${authState.userRole}');
        
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
