import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../widgets/course/course_card.dart';
import 'course_details_screen.dart';

class InstructorDetailsScreen extends StatefulWidget {
  final String mentorId;
  final Map<String, dynamic>? mentorData;

  const InstructorDetailsScreen({
    super.key,
    required this.mentorId,
    this.mentorData,
  });

  @override
  State<InstructorDetailsScreen> createState() => _InstructorDetailsScreenState();
}

class _InstructorDetailsScreenState extends State<InstructorDetailsScreen> {
  List<Map<String, dynamic>> _mentorCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMentorCourses();
  }

  void _loadMentorCourses() {
    context.read<CourseBloc>().add(const LoadCourses());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Instructor Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseLoaded) {
            setState(() {
              // Filter courses by mentorId
              _mentorCourses = state.courses.where((course) {
                final courseMentorId = course['mentorId']?.toString() ?? '';
                return courseMentorId == widget.mentorId && course['isPublished'] == true;
              }).toList();
              _isLoading = false;
            });
          } else if (state is CourseError) {
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
        },
        child: RefreshIndicator(
          onRefresh: () async {
            _loadMentorCourses();
          },
          color: AppTheme.primaryLight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructor Header
                _buildInstructorHeader(isDark),

                // Courses Section
                _buildCoursesSection(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorHeader(bool isDark) {
    final mentorName = widget.mentorData?['name'] ?? 'Instructor';
    final mentorTitle = widget.mentorData?['title'] ?? 'Course Instructor';
    final mentorBio = widget.mentorData?['bio'] ?? 'Experienced instructor with years of teaching experience.';
    final mentorAvatarUrl = widget.mentorData?['avatarUrl'];
    final mentorEmail = widget.mentorData?['email'];
    final mentorExpertise = widget.mentorData?['expertise'] as List<dynamic>?;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.secondaryLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    backgroundImage: mentorAvatarUrl != null && mentorAvatarUrl.isNotEmpty
                        ? NetworkImage(mentorAvatarUrl)
                        : null,
                    child: mentorAvatarUrl == null || mentorAvatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Name
              Text(
                mentorName,
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                mentorTitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              if (mentorEmail != null && mentorEmail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mentorEmail,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Bio
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primaryDark.withOpacity(0.1)
                      : AppTheme.primaryLight.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryDark.withOpacity(0.2)
                        : AppTheme.primaryLight.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  mentorBio,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Expertise Tags
              if (mentorExpertise != null && mentorExpertise.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: mentorExpertise.map((expertise) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryLight.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        expertise.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // Stats Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.school,
                      label: 'Courses',
                      value: _mentorCourses.length.toString(),
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    _buildStatItem(
                      icon: Icons.people,
                      label: 'Students',
                      value: _calculateTotalStudents().toString(),
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    _buildStatItem(
                      icon: Icons.star,
                      label: 'Rating',
                      value: _calculateAverageRating().toStringAsFixed(1),
                      color: Colors.amber,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  int _calculateTotalStudents() {
    int total = 0;
    for (var course in _mentorCourses) {
      total += (course['studentCount'] as int? ?? 0);
    }
    return total;
  }

  double _calculateAverageRating() {
    if (_mentorCourses.isEmpty) return 0.0;
    double total = 0.0;
    for (var course in _mentorCourses) {
      total += (course['rating'] as num? ?? 0.0).toDouble();
    }
    return total / _mentorCourses.length;
  }

  Widget _buildCoursesSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school,
                  color: AppTheme.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Courses by ${widget.mentorData?['name'] ?? 'Instructor'}',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Courses List
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _mentorCourses.isEmpty
                  ? _buildEmptyState(isDark)
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _mentorCourses.length,
                      itemBuilder: (context, index) {
                        final course = _mentorCourses[index];
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
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
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
              'No Published Courses',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This instructor hasn\'t published any courses yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ),
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

  void _navigateToCourseDetails(BuildContext context, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }
}
