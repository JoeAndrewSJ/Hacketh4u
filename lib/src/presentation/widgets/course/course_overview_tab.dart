import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/mentor/mentor_bloc.dart';
import '../../../core/bloc/mentor/mentor_event.dart';
import '../../../core/bloc/mentor/mentor_state.dart';
import 'course_info_section.dart';
import 'certificate_download_widget.dart';

class CourseOverviewTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;

  const CourseOverviewTab({
    super.key,
    required this.course,
    required this.isDark,
  });

  @override
  State<CourseOverviewTab> createState() => _CourseOverviewTabState();
}

class _CourseOverviewTabState extends State<CourseOverviewTab> {
  Map<String, dynamic>? mentorData;
  bool _isCurriculumExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  void _loadMentorData() {
    final mentorId = widget.course['mentorId'];
    if (mentorId != null) {
      context.read<MentorBloc>().add(LoadMentor(mentorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MentorBloc, MentorState>(
      listener: (context, state) {
        if (state is MentorState && state.selectedMentor != null) {
          setState(() {
            mentorData = state.selectedMentor;
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Description
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            
            // Curriculum
            _buildCurriculumSection(),
            const SizedBox(height: 24),
            
            // Subscription Period
            _buildSubscriptionPeriodSection(),
            const SizedBox(height: 24),
            
            // Course Stats
            _buildCourseStatsSection(),
            const SizedBox(height: 24),
            
            // Instructor Section
            _buildInstructorSection(),
            const SizedBox(height: 24),
            
            // Certificate Download Section (only show if user has access)
            CertificateDownloadWidget(
              courseId: widget.course['id'],
              courseTitle: widget.course['title'] ?? 'Course',
              isDark: widget.isDark,
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = widget.course['description'] ?? 'No description available';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this course',
          style: AppTextStyles.h3.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDescriptionContent(description),
      ],
    );
  }

  Widget _buildDescriptionContent(String description) {
    // Check if description has line breaks
    if (!description.contains('\n')) {
      // Single paragraph - display as regular text
      return Text(
        description,
        textAlign: TextAlign.justify,
        style: AppTextStyles.bodyMedium.copyWith(
          color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          height: 1.6,
        ),
      );
    }

    // Multiple lines - display with bullet points
    final lines = description.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      return Text(
        'No description available',
        style: AppTextStyles.h3.copyWith(
          color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          height: 1.6,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildDescriptionPoint(line)).toList(),
    );
  }

  Widget _buildDescriptionPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point.trim(),
              textAlign: TextAlign.justify,
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumSection() {
    final curriculum = widget.course['curriculum'] ?? '';
    
    if (curriculum.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Curriculum',
          style: AppTextStyles.h3.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildCurriculumContent(curriculum),
      ],
    );
  }

  Widget _buildCurriculumContent(String curriculum) {
    // Split curriculum by lines and filter out empty lines
    final lines = curriculum.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show first 3 lines by default, or all if less than 3
    final maxInitialLines = 3;
    final shouldShowSeeMore = lines.length > maxInitialLines;
    final displayLines = _isCurriculumExpanded ? lines : lines.take(maxInitialLines).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayLines.map((line) => _buildCurriculumPoint(line)),
        if (shouldShowSeeMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCurriculumExpanded = !_isCurriculumExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  _isCurriculumExpanded ? 'See less' : 'See more',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isCurriculumExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurriculumPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point.trim(),
              textAlign: TextAlign.justify,
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatsSection() {
    final moduleCount = widget.course['moduleCount'] ?? 0;
    final videoCount = widget.course['totalVideos'] ?? 0;
    final quizCount = (widget.course['quizzes'] as List?)?.length ?? 0;
    final totalDuration = widget.course['totalDuration'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course content',
            style: AppTextStyles.h3.copyWith(
              color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.video_library,
                  label: 'Videos',
                  value: '$videoCount',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.folder,
                  label: 'Modules',
                  value: '$moduleCount',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  label: 'Quizzes',
                  value: '$quizCount',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _formatDuration(totalDuration),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
          style: AppTextStyles.h3.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

Widget _buildInstructorSection() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.isDark 
            ? [
                AppTheme.surfaceDark,
                AppTheme.surfaceDark.withOpacity(0.8),
              ]
            : [
                Colors.white,
                Colors.grey.shade50,
              ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: widget.isDark 
            ? Colors.grey[700]!.withOpacity(0.3)
            : Colors.grey[200]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (widget.isDark ? Colors.black : Colors.grey).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Instructor',
              style: AppTextStyles.h3.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Instructor Profile
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with gradient border
            Container(
              padding: const EdgeInsets.all(3),
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
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.transparent,
                  backgroundImage: mentorData?['avatarUrl'] != null && 
                      mentorData!['avatarUrl'].isNotEmpty
                      ? NetworkImage(mentorData!['avatarUrl'])
                      : null,
                  onBackgroundImageError: mentorData?['avatarUrl'] != null && 
                      mentorData!['avatarUrl'].isNotEmpty
                      ? (exception, stackTrace) {
                          print('Error loading mentor image: $exception');
                        }
                      : null,
                  child: mentorData?['avatarUrl'] == null || 
                      mentorData!['avatarUrl'].isEmpty
                      ? Icon(
                          Icons.person,
                          size: 36,
                          color: widget.isDark 
                              ? AppTheme.textSecondaryDark 
                              : AppTheme.textSecondaryLight,
                        )
                      : null,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Instructor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    mentorData?['name'] ?? 
                        widget.course['instructor'] ?? 
                        widget.course['instructorName'] ?? 
                        'Instructor Name',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: widget.isDark 
                          ? AppTheme.textPrimaryDark 
                          : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Title
                  Text(
                    mentorData?['title'] ?? 'Course Instructor',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.isDark 
                          ? AppTheme.textSecondaryDark 
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Bio
                  Text(
                    mentorData?['bio'] ?? 
                        'Experienced instructor with years of teaching experience.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.isDark 
                          ? AppTheme.textSecondaryDark 
                          : AppTheme.textSecondaryLight,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildSubscriptionPeriodSection() {
    final subscriptionPeriod = widget.course['subscriptionPeriod'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark 
            ? AppTheme.surfaceDark.withOpacity(0.5)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark 
              ? AppTheme.inputBorderDark.withOpacity(0.3)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: subscriptionPeriod == 0 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              subscriptionPeriod == 0 ? Icons.all_inclusive : Icons.schedule,
              color: subscriptionPeriod == 0 ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Period',
                  style: AppTextStyles.h3.copyWith(
                    color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subscriptionPeriod == 0 
                      ? 'Lifetime Access'
                      : '${subscriptionPeriod} Days Access',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: subscriptionPeriod == 0 
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subscriptionPeriod == 0 
                      ? 'You will have unlimited access to this course content'
                      : 'You will have access to this course for ${subscriptionPeriod} days from purchase',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
