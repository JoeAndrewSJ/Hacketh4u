import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';
import '../../../data/models/user_progress_model.dart';
import '../../widgets/video/video_list_widget.dart';

class CourseModulesSection extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> modules;
  final bool isLoading;
  final bool isDark;
  final Function(Map<String, dynamic>) onModuleTap;
  final Function(Map<String, dynamic>)? onPremiumTap;
  final Function(Map<String, dynamic>)? onVideoTap;
  final String? selectedVideoId;
  final bool hasCourseAccess;

  const CourseModulesSection({
    super.key,
    required this.course,
    required this.modules,
    required this.isLoading,
    required this.isDark,
    required this.onModuleTap,
    this.onPremiumTap,
    this.onVideoTap,
    this.selectedVideoId,
    required this.hasCourseAccess,
  });

  @override
  State<CourseModulesSection> createState() => _CourseModulesSectionState();
}

class _CourseModulesSectionState extends State<CourseModulesSection> {
  int? _expandedModuleIndex;
  List<Map<String, dynamic>> _moduleVideos = [];
  bool _isLoadingVideos = false;
  Map<String, double> _videoProgress = {}; // videoId -> watchPercentage
  Map<String, ModuleProgress> _moduleProgresses = {}; // moduleId -> ModuleProgress

  @override
  void initState() {
    super.initState();
    // Load user progress for this course
    _loadUserProgress();
  }

  void _loadUserProgress() {
    if (widget.course['id'] != null) {
      context.read<UserProgressBloc>().add(
        LoadUserProgress(courseId: widget.course['id']),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is VideosLoaded) {
              setState(() {
                _moduleVideos = state.videos;
                _isLoadingVideos = false;
              });
            }
          },
        ),
        BlocListener<UserProgressBloc, UserProgressState>(
          listener: (context, state) {
            if (state is UserProgressLoaded) {
              // Extract video progress from user progress
              final videoProgress = <String, double>{};
              final moduleProgresses = <String, ModuleProgress>{};

              for (final moduleProgress in state.userProgress.moduleProgresses.values) {
                moduleProgresses[moduleProgress.moduleId] = moduleProgress;
                for (final videoProgressEntry in moduleProgress.videoProgresses.entries) {
                  videoProgress[videoProgressEntry.key] = videoProgressEntry.value.watchPercentage;
                }
              }
              setState(() {
                _videoProgress = videoProgress;
                _moduleProgresses = moduleProgresses;
              });
            }
          },
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress Section
            _buildOverallProgress(),
            const SizedBox(height: 24),

            Text(
              'Course Curriculum',
              style: AppTextStyles.h3.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (widget.modules.isEmpty)
              _buildEmptyState()
            else
              _buildModulesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    // Calculate overall progress from all modules
    double totalPercentage = 0.0;
    int moduleCount = 0;

    for (var module in widget.modules) {
      final moduleId = module['id']?.toString();
      if (moduleId != null && _moduleProgresses.containsKey(moduleId)) {
        final progress = _moduleProgresses[moduleId]!;
        totalPercentage += progress.completionPercentage;
        moduleCount++;
      }
    }

    final overallPercentage = moduleCount > 0 ? (totalPercentage / moduleCount).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
          width: 1,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '$overallPercentage%',
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallPercentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve completed $overallPercentage% of the course',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No modules available',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesList() {
    return Column(
      children: widget.modules.asMap().entries.map((entry) {
        final index = entry.key;
        final module = entry.value;
        return _buildModuleItem(module, index + 1, index);
      }).toList(),
    );
  }

  Widget _buildModuleItem(Map<String, dynamic> module, int moduleNumber, int moduleIndex) {
    print('Module: $module');
    final isPremium = module['isPremium'] ?? (module['type'] == 'premium');
    // If user has course access, treat all content as accessible
    final hasAccess = !isPremium || widget.hasCourseAccess;
    final videoCount = module['videoCount'] ?? 0;
    final duration = module['totalDuration'] ?? 0;
    final isExpanded = _expandedModuleIndex == moduleIndex;
    
    // Get module completion status
    final moduleId = module['id'] as String?;
    final moduleProgress = moduleId != null ? _moduleProgresses[moduleId] : null;
    final isModuleCompleted = moduleProgress?.isCompleted ?? false;
    final completionPercentage = moduleProgress?.completionPercentage ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module Header
          InkWell(
            onTap: () => _toggleModuleExpansion(moduleIndex, module),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Orange circular play icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Module Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Module Title
                        Text(
                          'Module $moduleNumber: ${module['title'] ?? 'Untitled Module'}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Metadata row with bullet separators
                        Row(
                          children: [
                            // Video count
                            Icon(
                              Icons.video_library_outlined,
                              size: 13,
                              color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF424242),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$videoCount videos',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF424242),
                                fontSize: 12,
                              ),
                            ),
                            // Bullet separator
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF9E9E9E),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Duration
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF424242),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatDuration(duration),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF424242),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Blue circular progress badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${completionPercentage.toInt()}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Expand/Collapse Chevron
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content (Videos)
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _isLoadingVideos
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _moduleVideos.isNotEmpty
                      ? VideoListWidget(
                          videos: _moduleVideos,
                          isDark: widget.isDark,
                          onVideoTap: widget.onVideoTap ?? (video) {
                            // Default video tap handler
                          },
                          onPremiumTap: widget.onPremiumTap,
                          selectedVideoId: widget.selectedVideoId,
                          isParentModulePremium: isPremium,
                          hasCourseAccess: widget.hasCourseAccess,
                          courseId: widget.course['id'],
                          moduleId: module['id'],
                          videoProgress: _videoProgress,
                        )
                      : _buildNoVideosState(),
            ),
        ],
      ),
    );
  }

  void _toggleModuleExpansion(int moduleIndex, Map<String, dynamic> module) {
    // Allow expansion for all modules (free and premium)
    // Premium modules will show locked content when expanded
    setState(() {
      if (_expandedModuleIndex == moduleIndex) {
        _expandedModuleIndex = null;
        _moduleVideos = [];
      } else {
        _expandedModuleIndex = moduleIndex;
        _isLoadingVideos = true;
        // Load videos for this module from repository
        _loadModuleVideos(module);
      }
    });
  }

  void _loadModuleVideos(Map<String, dynamic> module) {
    final courseId = widget.course['id'];
    final moduleId = module['id'];
    
    if (courseId != null && moduleId != null) {
      // Load videos from repository
      context.read<CourseBloc>().add(LoadModuleVideos(
        courseId: courseId,
        moduleId: moduleId,
      ));
    } else {
      // Fallback to module's videos array if available
      setState(() {
        _moduleVideos = _getVideosForModule(module);
        _isLoadingVideos = false;
      });
    }
  }

  List<Map<String, dynamic>> _getVideosForModule(Map<String, dynamic> module) {
    // Get videos from module data (fallback when videos collection is not available)
    final videos = module['videos'] as List<dynamic>? ?? [];
    final moduleId = module['id'];
    
    // Convert to List<Map<String, dynamic>> and add fallback data if needed
    return videos.map((video) {
      final videoMap = Map<String, dynamic>.from(video as Map);
      
      // Ensure required fields have fallback values
      videoMap['id'] = videoMap['id'] ?? 'unknown';
      videoMap['title'] = videoMap['title'] ?? 'Untitled Video';
      videoMap['videoUrl'] = videoMap['videoUrl'] ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      videoMap['duration'] = videoMap['duration'] ?? 0;
      videoMap['isPremium'] = videoMap['isPremium'] ?? false;
      videoMap['moduleId'] = moduleId; // Add moduleId for progress tracking
      
      return videoMap;
    }).toList();
  }

  Widget _buildNoVideosState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos available',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Videos will be added soon',
              style: AppTextStyles.bodySmall.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
}
