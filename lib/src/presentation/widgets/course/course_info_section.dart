import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/mentor/mentor_bloc.dart';
import '../../../core/bloc/mentor/mentor_event.dart';
import '../../../core/bloc/mentor/mentor_state.dart';

class CourseInfoSection extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;

  const CourseInfoSection({
    super.key,
    required this.course,
    required this.isDark,
  });

  @override
  State<CourseInfoSection> createState() => _CourseInfoSectionState();
}

class _CourseInfoSectionState extends State<CourseInfoSection> {
  Map<String, dynamic>? mentorData;

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  void _loadMentorData() {
    final mentorId = widget.course['mentorId'];
    print('CourseInfoSection: Loading mentor data for mentorId: $mentorId');
    if (mentorId != null) {
      context.read<MentorBloc>().add(LoadMentor(mentorId));
    } else {
      print('CourseInfoSection: No mentorId found in course data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MentorBloc, MentorState>(
      listener: (context, state) {
        if (state.selectedMentor != null) {
          print('CourseInfoSection: Mentor data loaded: ${state.selectedMentor}');
          setState(() {
            mentorData = state.selectedMentor;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and Reviews
            _buildRatingSection(),
            const SizedBox(height: 20),
            
            // Description
            _buildDescriptionSection(),
            const SizedBox(height: 20),
            
            // Course Stats
            _buildStatsSection(),
            const SizedBox(height: 20),
            
            // Instructor Info
            _buildInstructorSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = (widget.course['rating'] ?? 0.0).toDouble();
    final studentCount = widget.course['studentCount'] ?? 0;
    
    return Row(
      children: [
        // Star Rating
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.bodyLarge.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '($studentCount reviews)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final description = widget.course['description'] ?? 'No description available.';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you\'ll learn',
          style: AppTextStyles.h3.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalDuration = widget.course['totalDuration'] ?? 0;
    final moduleCount = widget.course['moduleCount'] ?? 0;
    final totalVideos = widget.course['totalVideos'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.video_library,
            label: 'Modules',
            value: moduleCount.toString(),
          ),
          _buildStatItem(
            icon: Icons.play_circle,
            label: 'Videos',
            value: totalVideos.toString(),
          ),
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Duration',
            value: _formatDuration(totalDuration),
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
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryLight,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
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
    final mentorName = mentorData?['name'] ?? 'Hackethos4U Team';
    final mentorBio = mentorData?['bio'] ?? 'Expert in Cybersecurity & Ethical Hacking';
    final mentorImage = mentorData?['avatarUrl'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
            backgroundImage: mentorImage != null && mentorImage.isNotEmpty
                ? NetworkImage(mentorImage)
                : null,
            onBackgroundImageError: mentorImage != null && mentorImage.isNotEmpty
                ? (exception, stackTrace) {
                    print('Error loading mentor image: $exception');
                  }
                : null,
            child: mentorImage == null || mentorImage.isEmpty
                ? Icon(
                    Icons.person,
                    color: AppTheme.primaryLight,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mentorName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mentorBio,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
}
