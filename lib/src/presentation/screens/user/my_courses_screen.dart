import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../widgets/course/purchased_course_card.dart';
import 'course_details_screen.dart';
import 'all_courses_screen.dart';

enum CourseFilter { all, inProgress, completed }

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  List<Map<String, dynamic>> _purchasedCourses = [];
  bool _isLoading = true;
  bool _hasLoadedData = false;
  CourseFilter _selectedFilter = CourseFilter.all;

  @override
  void initState() {
    super.initState();
    _loadCoursesWithTimeout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData && !_isLoading) {
      _loadCoursesWithTimeout();
    }
  }

  void _loadCoursesWithTimeout() {
    if (_purchasedCourses.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
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

  Future<void> _refreshCourses() async {
    setState(() {
      _hasLoadedData = false;
    });
    _loadCoursesWithTimeout();
  }

  List<Map<String, dynamic>> get _filteredCourses {
    switch (_selectedFilter) {
      case CourseFilter.all:
        return _purchasedCourses;
      case CourseFilter.inProgress:
        return _purchasedCourses.where((course) {
          final progressData = course['progress'] as Map<String, dynamic>?;
          final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;
          return progressPercentage > 0 && progressPercentage < 100;
        }).toList();
      case CourseFilter.completed:
        return _purchasedCourses.where((course) {
          final progressData = course['progress'] as Map<String, dynamic>?;
          final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;
          return progressPercentage >= 100;
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Courses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<CourseAccessBloc, CourseAccessState>(
        listener: (context, state) {
          if (state is PurchasedCoursesWithDetailsLoaded) {
            if (mounted) {
              setState(() {
                _purchasedCourses = state.purchasedCourses;
                _isLoading = false;
                _hasLoadedData = true;
              });
            }
          } else if (state is PurchasedCoursesLoaded) {
            if (mounted) {
              setState(() {
                _purchasedCourses = [];
                _isLoading = false;
              });
            }
            if (_purchasedCourses.isEmpty) {
              context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
            }
          } else if (state is CourseAccessLoading) {
            if (mounted && _purchasedCourses.isEmpty) {
              setState(() {
                _isLoading = true;
              });
            }
          } else if (state is CourseAccessError) {
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
          }
        },
        child: Column(
          children: [
            // Tab Filter Bar
            _buildTabFilterBar(isDark),

            // Course List
            Expanded(
              child: _buildBody(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabFilterBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All Courses',
              filter: CourseFilter.all,
              count: _purchasedCourses.length,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'In Progress',
              filter: CourseFilter.inProgress,
              count: _purchasedCourses.where((course) {
                final progressData = course['progress'] as Map<String, dynamic>?;
                final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;
                return progressPercentage > 0 && progressPercentage < 100;
              }).length,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Completed',
              filter: CourseFilter.completed,
              count: _purchasedCourses.where((course) {
                final progressData = course['progress'] as Map<String, dynamic>?;
                final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;
                return progressPercentage >= 100;
              }).length,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required CourseFilter filter,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryLight
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryLight,
            ),
            SizedBox(height: 16),
            Text(
              'Loading your courses...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_purchasedCourses.isEmpty) {
      return _buildEmptyState(isDark, 'No Purchased Courses',
          'You haven\'t purchased any courses yet.\nBrowse courses and make your first purchase!');
    }

    final filteredCourses = _filteredCourses;

    if (filteredCourses.isEmpty) {
      String title = '';
      String message = '';

      switch (_selectedFilter) {
        case CourseFilter.inProgress:
          title = 'No Courses In Progress';
          message = 'Start learning from your purchased courses\nto see them here!';
          break;
        case CourseFilter.completed:
          title = 'No Completed Courses';
          message = 'Complete your courses to see them here.\nKeep learning!';
          break;
        default:
          title = 'No Courses';
          message = 'No courses found in this category.';
      }

      return _buildEmptyState(isDark, title, message);
    }

    return _buildCoursesList(filteredCourses, isDark);
  }

  Widget _buildEmptyState(bool isDark, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                height: 1.5,
              ),
            ),
            if (_purchasedCourses.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.explore, size: 20),
                label: const Text(
                  'Browse Courses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(List<Map<String, dynamic>> courses, bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshCourses,
      color: AppTheme.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
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
