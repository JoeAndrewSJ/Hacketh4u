import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/course/admin_course_card.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/common/course_edit_popup.dart';
import '../../widgets/common/course_delete_dialog.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import 'course_creation_screen.dart';
import 'course_modules_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'newest';
  bool _isRefreshing = false;

  // Courses will be loaded from BLoC state
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    print('AllCoursesScreen: Initializing and loading courses...');
    // Load courses when screen initializes
    context.read<CourseBloc>().add(const LoadCourses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = true; // TODO: Get from auth state
    
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        print('AllCoursesScreen: Received state: ${state.runtimeType}');
        if (state is CourseLoaded) {
          print('AllCoursesScreen: CourseLoaded with ${state.courses.length} courses');
          setState(() {
            _courses = state.courses;
          });
        } else if (state is CourseCreated) {
          print('AllCoursesScreen: CourseCreated, refreshing list...');
          // Refresh courses list when a new course is created
          context.read<CourseBloc>().add(const LoadCourses());
        } else if (state is CourseDeleted) {
          print('AllCoursesScreen: CourseDeleted, refreshing list...');
          // Refresh courses list when a course is deleted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<CourseBloc>().add(const LoadCourses());
        } else if (state is CourseError) {
          print('AllCoursesScreen: CourseError: ${state.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          // Update courses list from state
          if (state is CourseLoaded) {
            _courses = state.courses;
          }
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('All Courses'),
              centerTitle: true,
              backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
              foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
              elevation: 0,
              
            ),
            body: RefreshIndicator(
              onRefresh: _refreshCourses,
              child: Column(
                children: [
                  // Search Bar
                  _buildSearchBar(context),
                  
                  // Course Count
                  _buildCourseCount(context),
                  
                  // Courses Grid
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _courses.isEmpty
                            ? _buildEmptyState(context)
                            : _buildCoursesGrid(context, isAdmin),
                  ),
                ],
              ),
            ),

          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primaryLight,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        ),
      ),
    );
  }

  Widget _buildCourseCount(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredCourses = _getFilteredCourses();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${filteredCourses.length} courses found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            'Sorted by: ${_getSortLabel()}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesGrid(BuildContext context, bool isAdmin) {
    final filteredCourses = _getFilteredCourses();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return AdminCourseCard(
          id: course['id'] ?? '',
          title: course['title'] ?? 'Untitled Course',
          description: course['description'] ?? 'No description available',
          thumbnailUrl: course['thumbnailUrl'] ?? '',
          rating: (course['rating'] ?? 0.0).toDouble(),
          studentCount: course['studentCount'] ?? 0,
          duration: _formatDuration(course['totalDuration'] ?? 0),
          onTap: () => _showCourseOptions(course),
          onEdit: () => _editCourse(course),
          onDelete: () => _deleteCourse(course),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
            'No courses found',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCourses() {
    var courses = _courses;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      courses = courses.where((course) {
        return course['title'].toLowerCase().contains(searchQuery) ||
               course['description'].toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    // Apply sorting
    courses.sort((a, b) {
      switch (_selectedSort) {
        case 'newest':
          return b['createdAt'].compareTo(a['createdAt']);
        case 'oldest':
          return a['createdAt'].compareTo(b['createdAt']);
        case 'rating':
          return b['rating'].compareTo(a['rating']);
        case 'students':
          return b['studentCount'].compareTo(a['studentCount']);
        case 'title':
          return a['title'].compareTo(b['title']);
        default:
          return 0;
      }
    });
    
    return courses;
  }

  String _getSortLabel() {
    switch (_selectedSort) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'rating':
        return 'Rating';
      case 'students':
        return 'Students';
      case 'title':
        return 'Title';
      default:
        return 'Newest';
    }
  }

  void _onSearchChanged(String query) {
    setState(() {});
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  Widget _buildSortBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortOptions = [
      {'value': 'newest', 'label': 'Newest First'},
      {'value': 'oldest', 'label': 'Oldest First'},
      {'value': 'rating', 'label': 'Highest Rated'},
      {'value': 'students', 'label': 'Most Students'},
      {'value': 'title', 'label': 'Title A-Z'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort By',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ...sortOptions.map((option) => ListTile(
            title: Text(option['label']!),
            leading: Radio<String>(
              value: option['value']!,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
              },
              activeColor: AppTheme.primaryLight,
            ),
          )),
        ],
      ),
    );
  }


  Future<void> _refreshCourses() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Refresh courses using BLoC
    context.read<CourseBloc>().add(const LoadCourses());
    
    setState(() {
      _isRefreshing = false;
    });
  }

  void _viewCourseDetails(Map<String, dynamic> course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CourseModulesScreen(course: course),
      ),
    );
  }

  void _editCourse(Map<String, dynamic> course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CourseCreationScreen(courseToEdit: course),
      ),
    );
  }
  
  void _showCourseOptions(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => CourseEditPopup(
        courseTitle: course['title'] ?? 'Untitled Course',
        onView: () => _viewCourseDetails(course),
        onEdit: () => _editCourse(course),
        onDelete: () => _deleteCourse(course),
      ),
    );
  }

  void _deleteCourse(Map<String, dynamic> course) {
    print('AllCoursesScreen: _deleteCourse called for course: ${course['id']}');
    showDialog(
      context: context,
      builder: (context) => CourseDeleteDialog(
        courseTitle: course['title'] ?? 'Untitled Course',
        courseId: course['id'] ?? '',
        onConfirm: () {
          print('AllCoursesScreen: Delete confirmed for course: ${course['id']}');
          // Delete course using BLoC
          context.read<CourseBloc>().add(DeleteCourse(course['id']));
        },
        onCancel: () {
          print('AllCoursesScreen: Delete cancelled');
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _createNewCourse() {
    // TODO: Navigate to course creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to course creation')),
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
}
