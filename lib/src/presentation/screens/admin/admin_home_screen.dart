import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackethos4u/src/core/bloc/auth/auth_state.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'course_creation_screen.dart';
import 'mentor_creation_screen.dart';
import 'all_courses_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthBloc, dynamic>(
          builder: (context, authState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Extra bottom padding for nav bar
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryDark 
                            : AppTheme.primaryLight,
                        Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.secondaryDark 
                            : AppTheme.secondaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryDark 
                            : AppTheme.primaryLight).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Admin!',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authState.user?.email ?? 'admin@hackethos4u.com',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Admin Actions
                Text(
                  'Admin Actions',
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.textPrimaryDark 
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Admin Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildAdminCard(
                      context,
                      'Create Course',
                      'Design and publish new courses',
                      Icons.school,
                      () => _navigateToCreateCourse(context),
                    ),
                    _buildAdminCard(
                      context,
                      'Create Mentor',
                      'Add new mentors to the platform',
                      Icons.person_add,
                      () => _navigateToCreateMentor(context),
                    ),
                    _buildAdminCard(
                      context,
                      'All Courses',
                      'Manage existing courses',
                      Icons.library_books,
                      () => _navigateToAllCourses(context),
                    ),
                    _buildStatCard(
                      context,
                      'Total Students',
                      '1,234',
                      Icons.people,
                      AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
               
              ],
            ),
          );
        },
      ),
    )
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateCourse(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CourseCreationScreen(),
      ),
    );
  }

  void _navigateToCreateMentor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MentorCreationScreen(),
      ),
    );
  }

  void _navigateToAllCourses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllCoursesScreen(),
      ),
    );
  }

 
}
