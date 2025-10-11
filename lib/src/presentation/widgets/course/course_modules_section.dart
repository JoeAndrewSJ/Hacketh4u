import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
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
  });

  @override
  State<CourseModulesSection> createState() => _CourseModulesSectionState();
}

class _CourseModulesSectionState extends State<CourseModulesSection> {
  int? _expandedModuleIndex;
  List<Map<String, dynamic>> _moduleVideos = [];
  bool _isLoadingVideos = false;
  bool _hasCourseAccess = false;
  bool _isCheckingAccess = true;

  @override
  void initState() {
    super.initState();
    // Check course access when widget initializes
    _checkCourseAccess();
  }

  void _checkCourseAccess() {
    context.read<CourseAccessBloc>().add(
      CheckCourseAccess(courseId: widget.course['id']),
    );
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
        BlocListener<CourseAccessBloc, CourseAccessState>(
          listener: (context, state) {
            if (state is CourseAccessChecked) {
              setState(() {
                _hasCourseAccess = state.hasAccess;
                _isCheckingAccess = false;
              });
              print('Course access checked: ${state.hasAccess}');
            } else if (state is CourseAccessError) {
              setState(() {
                _isCheckingAccess = false;
              });
              print('Course access error: ${state.error}');
            }
          },
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Content',
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
    final hasAccess = !isPremium || _hasCourseAccess;
    final videoCount = module['videoCount'] ?? 0;
    final duration = module['totalDuration'] ?? 0;
    final isExpanded = _expandedModuleIndex == moduleIndex;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              decoration: BoxDecoration(
                color: isPremium && !hasAccess
                    ? (widget.isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100]!.withOpacity(0.5))
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Module Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasAccess 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasAccess ? Icons.play_circle : Icons.lock,
                      color: hasAccess ? Colors.green : Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Module Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Module $moduleNumber: ${module['title'] ?? 'Untitled Module'}',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPremium && !hasAccess)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Premium',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (isPremium && !hasAccess) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Premium Content - Purchase to Access',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.video_library,
                                size: 14,
                                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$videoCount videos',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(duration),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Expand/Collapse Icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
                          hasCourseAccess: _hasCourseAccess,
                          courseId: widget.course['id'],
                          moduleId: module['id'],
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
