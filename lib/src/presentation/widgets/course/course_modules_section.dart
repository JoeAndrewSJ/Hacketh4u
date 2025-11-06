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
import '../../../data/models/quiz_model.dart';
import '../../widgets/video/video_list_widget.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../screens/quiz/quiz_taking_screen.dart';

class CourseModulesSection extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> modules;
  final List<QuizModel> quizzes;
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
    required this.quizzes,
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
  Map<String, QuizResultSummary> _quizSummaries = {}; // quizId -> QuizResultSummary

  @override
  void initState() {
    super.initState();
    // Load user progress for this course
    _loadUserProgress();
    // Load quiz summaries
    _loadQuizSummaries();
  }

  void _loadUserProgress() {
    if (widget.course['id'] != null) {
      context.read<UserProgressBloc>().add(
        LoadUserProgress(courseId: widget.course['id']),
      );
    }
  }

  void _loadQuizSummaries() async {
    if (widget.quizzes.isEmpty) return;

    final quizRepository = sl<QuizRepository>();
    final summaries = <String, QuizResultSummary>{};

    for (final quiz in widget.quizzes) {
      try {
        final summary = await quizRepository.getUserQuizResultSummary(quiz.id);
        if (summary != null) {
          summaries[quiz.id] = summary;
        }
      } catch (e) {
        print('Error loading quiz summary for ${quiz.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _quizSummaries = summaries;
      });
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
          
          // Expanded Content (Videos and Quizzes)
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Videos Section
                        if (_moduleVideos.isNotEmpty)
                          VideoListWidget(
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
                        else
                          _buildNoVideosState(),

                        // Quizzes Section
                        _buildModuleQuizzes(module),
                      ],
                    ),
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

  Widget _buildModuleQuizzes(Map<String, dynamic> module) {
    final moduleId = module['id'] as String?;
    if (moduleId == null) return const SizedBox.shrink();

    // Filter quizzes for this module
    final moduleQuizzes = widget.quizzes
        .where((quiz) => quiz.moduleId == moduleId)
        .toList();

    if (moduleQuizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check module premium status - quizzes inherit this
    final isPremiumModule = module['isPremium'] ?? (module['type'] == 'premium');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quiz Cards - displayed directly like videos, no header
        ...moduleQuizzes.map((quiz) {
          final summary = _quizSummaries[quiz.id];
          return _buildQuizCard(quiz, isPremiumModule, summary);
        }).toList(),
      ],
    );
  }

  Widget _buildQuizCard(QuizModel quiz, bool isPremiumModule, QuizResultSummary? summary) {
    // Quizzes inherit premium status from their parent module
    final isPremium = isPremiumModule;
    final hasAccess = !isPremium || widget.hasCourseAccess;

    // Determine completion status
    final hasPassed = summary?.hasPassed ?? false;
    final hasAttempted = summary != null && summary.totalAttempts > 0;
    final bestPercentage = summary?.bestPercentage ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: hasAccess ? 1.0 : 0.6, // Dim locked content like videos
        child: InkWell(
          onTap: hasAccess ? () => _startQuiz(quiz) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quiz icon - matching video thumbnail style
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Light gray background like videos
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.quiz_outlined,
                      color: const Color(0xFF424242), // Dark gray icon like videos
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Quiz info - wrapped in Flexible to prevent overflow
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quiz.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 13,
                                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quiz.questions.length} questions',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.score_outlined,
                                size: 13,
                                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quiz.totalMarks} marks',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                                ),
                              ),
                            ],
                          ),
                          if (isPremium && !hasAccess)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Premium',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Completion status indicator - matching video style
                if (hasPassed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Passed',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasAttempted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${bestPercentage.toInt()}%',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz(QuizModel quiz) async {
    // Check if user has attempts remaining
    try {
      final quizRepository = sl<QuizRepository>();
      QuizResultSummary? summary;

      try {
        summary = await quizRepository.getUserQuizResultSummary(quiz.id);
      } catch (e) {
        print('Error fetching quiz summary: $e');
      }

      // Check if max attempts reached
      if (summary != null && !summary.canRetake && summary.remainingAttempts == 0) {
        _showMaxAttemptsReachedDialog(quiz, summary);
        return;
      }

      // Navigate to quiz screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizTakingScreen(
              courseId: widget.course['id'],
              quizId: quiz.id,
              quiz: quiz,
            ),
          ),
        );

        // Reload quiz summaries after returning from quiz
        if (mounted) {
          _loadQuizSummaries();
        }
      }
    } catch (e) {
      print('Error starting quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMaxAttemptsReachedDialog(QuizModel quiz, QuizResultSummary summary) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red blocked icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Maximum Attempts Reached',
                style: AppTextStyles.h3.copyWith(
                  color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'You have used all ${quiz.maxAttempts} ${quiz.maxAttempts == 1 ? "attempt" : "attempts"} for this quiz.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Best Score Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: summary.hasPassed
                        ? [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)]
                        : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: summary.hasPassed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Best Score',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Text(
                    //   '${summary.bestPercentage.toStringAsFixed(1)}%',
                    //   style: AppTextStyles.h1.copyWith(
                    //     color: summary.hasPassed ? Colors.green : Colors.orange,
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 32,
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.bestMarks}/${quiz.totalMarks} marks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Got It Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
