import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_event.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../widgets/course/purchased_course_card.dart';
import 'course_details_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<Map<String, dynamic>> _purchasedCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load purchased courses with details
    print('MyCoursesScreen: Initializing and loading purchased courses with details');
    _loadCoursesWithTimeout();
  }

  void _loadCoursesWithTimeout() {
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
    
    context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<CourseAccessBloc, CourseAccessState>(
        listener: (context, state) {
          print('MyCoursesScreen: Received state: ${state.runtimeType}');
          
          if (state is PurchasedCoursesWithDetailsLoaded) {
            print('MyCoursesScreen: Loading ${state.purchasedCourses.length} courses with details');
            setState(() {
              _purchasedCourses = state.purchasedCourses;
              _isLoading = false;
            });
          } else if (state is PurchasedCoursesLoaded) {
            // Handle the old state that returns List<String> - convert to empty list for now
            print('MyCoursesScreen: Received old PurchasedCoursesLoaded state, reloading with details');
            setState(() {
              _purchasedCourses = [];
              _isLoading = false;
            });
            // Reload with details
            context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
          } else if (state is CourseAccessLoading) {
            print('MyCoursesScreen: Loading state');
            setState(() {
              _isLoading = true;
            });
          } else if (state is CourseAccessError) {
            print('MyCoursesScreen: Error state: ${state.error}');
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading courses: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CourseAccessChecked) {
            // This state is from checking access to a single course, ignore it
            print('MyCoursesScreen: Ignoring CourseAccessChecked state (single course access check)');
          } else {
            print('MyCoursesScreen: Unknown state: ${state.runtimeType}');
          }
        },
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
                    // Navigate to courses tab (index 0)
                    // This would need to be implemented based on your navigation structure
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to courses tab to browse available courses'),
                        backgroundColor: Colors.blue,
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
