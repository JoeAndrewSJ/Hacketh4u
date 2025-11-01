import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../widgets/course/course_card.dart';
import '../../widgets/common/widgets.dart';
import 'course_details_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCourses() {
    context.read<CourseBloc>().add(const LoadCourses());
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        final title = course['title']?.toString().toLowerCase() ?? '';
        final description = course['description']?.toString().toLowerCase() ?? '';
        final searchQuery = _searchController.text.toLowerCase();
        return title.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Courses',
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
      ),
      body: BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseLoaded) {
            setState(() {
              _courses = state.courses;
              _filteredCourses = _courses;
            });
          } else if (state is CourseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(isDark),
            ),

            // Courses Grid
            Expanded(
              child: BlocBuilder<CourseBloc, CourseState>(
                builder: (context, state) {
                  if (state.isLoading && _courses.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (_filteredCourses.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadCourses();
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65, // Reduced from 0.8 to give more vertical space
                      ),
                      itemCount: _filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _filteredCourses[index];
                        return _buildCourseCard(context, course, isDark);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course, bool isDark) {
    return CourseCard(
      id: course['id'] ?? '',
      title: course['title'] ?? 'Untitled Course',
      description: course['description'] ?? 'No description available',
      thumbnailUrl: course['thumbnailUrl'] ?? '',
      rating: (course['rating'] ?? 0.0).toDouble(),
      studentCount: course['studentCount'] ?? 0,
      duration: _formatDuration(course['totalDuration'] ?? 0),
      isAdmin: false,
      onTap: () => _navigateToCourseDetails(context, course),
      useFixedWidth: false, // Let GridView control the width to prevent overflow
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? 'No Courses Found' : 'No Courses Available',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try adjusting your search terms'
                : 'Check back later for new courses',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isNotEmpty)
            CustomButton(
              text: 'Clear Search',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
              isOutlined: true,
            ),
        ],
      ),
    );
  }

  void _navigateToCourseDetails(BuildContext context, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _searchController,
        onChanged: (value) => _onSearchChanged(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search by title or description...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryLight,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
