import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/mentor/mentor_bloc.dart';
import '../../../core/bloc/mentor/mentor_event.dart';
import '../../../core/bloc/mentor/mentor_state.dart';
import '../../../data/models/quiz_model.dart';
import 'certificate_download_widget.dart';

class CourseOverviewTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final List<QuizModel> quizzes;

  const CourseOverviewTab({
    super.key,
    required this.course,
    required this.isDark,
    this.quizzes = const [],
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
            color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
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
          color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
          fontSize: 13,
          height: 1.6,
        ),
      );
    }

    // Multiple lines - display with bullet points
    final lines = description.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return Text(
        'No description available',
        style: AppTextStyles.bodyMedium.copyWith(
          color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
          fontSize: 13,
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.info_outline,
              color: const Color(0xFF9E9E9E),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.trim(),
              textAlign: TextAlign.justify,
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                fontSize: 13,
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
            color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isCurriculumExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryLight,
                  size: 18,
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.trim(),
              textAlign: TextAlign.justify,
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                fontSize: 13,
                height: 1.6,
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
    final quizCount = widget.quizzes.length;
    final totalDuration = widget.course['totalDuration'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course content',
            style: AppTextStyles.h3.copyWith(
              color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // First Row - 2 items
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.video_library,
                  label: 'Videos',
                  value: '$videoCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.folder,
                  label: 'Modules',
                  value: '$moduleCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second Row - 2 items
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  label: 'Quizzes',
                  value: '$quizCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _formatDuration(totalDuration),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: widget.isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildInstructorSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.person,
              color: widget.isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Instructor',
              style: AppTextStyles.h3.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
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
                      color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Title
                  Text(
                    mentorData?['title'] ?? 'Course Instructor',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bio
                  Text(
                    mentorData?['bio'] ??
                        'Experienced instructor with years of teaching experience.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      fontSize: 12,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            subscriptionPeriod == 0 ? Icons.all_inclusive : Icons.schedule,
            color: widget.isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Period',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subscriptionPeriod == 0
                      ? 'Lifetime Access - Unlimited access to all course content'
                      : '${subscriptionPeriod} Days Access - Access for ${subscriptionPeriod} days from purchase',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                    fontSize: 12,
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
