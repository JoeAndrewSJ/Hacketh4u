import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_event.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../../core/bloc/user_profile/user_profile_bloc.dart';
import '../../../core/bloc/user_profile/user_profile_event.dart';
import '../../../core/bloc/user_profile/user_profile_state.dart';
import '../../widgets/course/purchased_course_card.dart';
import '../../widgets/invoice/invoice_download_widget.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/user_model.dart';
import 'course_details_screen.dart';
import 'invoice_history_screen.dart';
import 'all_courses_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<Map<String, dynamic>> _purchasedCourses = [];
  bool _isLoading = true;
  bool _hasLoadedData = false; // Track if we've successfully loaded data
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Load purchased courses with details
    print('MyCoursesScreen: Initializing and loading purchased courses with details');
    _loadCoursesWithTimeout();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when the screen becomes active again
    print('MyCoursesScreen: didChangeDependencies called');
    print('MyCoursesScreen: Current courses count: ${_purchasedCourses.length}, isLoading: $_isLoading, hasLoadedData: $_hasLoadedData');
    
    // Only reload if we have never loaded data AND we're not currently loading
    if (!_hasLoadedData && !_isLoading) {
      print('MyCoursesScreen: Never loaded data, reloading courses');
      _loadCoursesWithTimeout();
    } else {
      print('MyCoursesScreen: Data already loaded or loading in progress, skipping reload');
    }
  }

  void _loadUserProfile() {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state.isAuthenticated && authBloc.state.user != null) {
      context.read<UserProfileBloc>().add(LoadUserProfile(uid: authBloc.state.user!.uid));
    }
  }

  void _loadCoursesWithTimeout() {
    // Only reset loading state if we don't already have data
    if (_purchasedCourses.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        print('MyCoursesScreen: Timeout reached, stopping loading');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading courses is taking longer than expected. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    
    print('MyCoursesScreen: Dispatching LoadPurchasedCoursesWithDetails event');
    context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
  }

  Future<void> _refreshCourses() async {
    print('MyCoursesScreen: Refreshing courses');
    // Reset the flag to allow fresh data loading
    setState(() {
      _hasLoadedData = false;
    });
    _loadCoursesWithTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Courses',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvoiceHistoryScreen(),
                ),
              );
            },
            tooltip: 'Invoice History',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CourseAccessBloc, CourseAccessState>(
            listener: (context, state) {
              print('MyCoursesScreen: Received state: ${state.runtimeType}');
              
              if (state is PurchasedCoursesWithDetailsLoaded) {
                print('MyCoursesScreen: Loading ${state.purchasedCourses.length} courses with details');
                if (mounted) {
                  setState(() {
                    _purchasedCourses = state.purchasedCourses;
                    _isLoading = false;
                    _hasLoadedData = true; // Mark that we've successfully loaded data
                  });
                }
              } else if (state is PurchasedCoursesLoaded) {
                // Handle the old state that returns List<String> - convert to empty list for now
                print('MyCoursesScreen: Received old PurchasedCoursesLoaded state, reloading with details');
                if (mounted) {
                  setState(() {
                    _purchasedCourses = [];
                    _isLoading = false;
                  });
                }
                // Only reload if we don't already have data
                if (_purchasedCourses.isEmpty) {
                  context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
                }
              } else if (state is CourseAccessLoading) {
                print('MyCoursesScreen: Loading state');
                // Only set loading to true if we don't already have data
                if (mounted && _purchasedCourses.isEmpty) {
                  setState(() {
                    _isLoading = true;
                  });
                }
              } else if (state is CourseAccessError) {
                print('MyCoursesScreen: Error state: ${state.error}');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading courses: ${state.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (state is CourseAccessChecked) {
                // This state is from checking access to a single course, ignore it completely
                print('MyCoursesScreen: Ignoring CourseAccessChecked state (single course access check)');
                // Don't do anything for this state
              }
              // Removed the else clause that was causing unnecessary reloads
            },
          ),
          BlocListener<UserProfileBloc, UserProfileState>(
            listener: (context, state) {
              if (state is UserProfileLoaded) {
                setState(() {
                  _currentUser = state.user;
                });
              }
            },
          ),
        ],
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your courses...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _refreshCourses();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_purchasedCourses.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCoursesList();
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Purchased Courses',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t purchased any courses yet.\nBrowse courses and make your first purchase!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Retry loading courses
                    _loadCoursesWithTimeout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to browse courses screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllCoursesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Browse Courses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: () async {
        // Reload purchased courses with timeout
        _loadCoursesWithTimeout();
      },
      color: AppTheme.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _purchasedCourses.length,
        itemBuilder: (context, index) {
          final course = _purchasedCourses[index];
          return PurchasedCourseCard(
            course: course,
            isDark: isDark,
            onTap: () => _navigateToCourseDetails(course),
          );
        },
      ),
    );
  }

  void _navigateToCourseDetails(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }
}
