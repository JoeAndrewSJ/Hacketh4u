import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/widgets.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../widgets/module/module_card.dart';
import '../../widgets/quiz/quiz_card.dart';
import '../../widgets/loading/hackethos_loading_component.dart';
import 'module_creation_screen.dart';
import 'quiz_creation_screen.dart';

class CourseModulesScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseModulesScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseModulesScreen> createState() => _CourseModulesScreenState();
}

class _CourseModulesScreenState extends State<CourseModulesScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _quizzes = [];
  String _selectedTab = 'modules';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index == 0 ? 'modules' : 'quizzes';
      });
    });
    _loadModules();
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadModules() {
    context.read<CourseBloc>().add(LoadCourseModules(widget.course['id']));
  }

  void _loadQuizzes() {
    context.read<QuizBloc>().add(LoadCourseQuizzes(courseId: widget.course['id']));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is ModulesLoaded) {
              setState(() {
                _modules = state.modules;
              });
            } else if (state is ModuleCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Module "${state.module['title']}" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadModules();
            } else if (state is ModuleUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Module "${state.module['title']}" updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadModules();
            } else if (state is ModuleDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Module deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadModules();
            } else if (state is CourseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizzesLoaded) {
              setState(() {
                _quizzes = state.quizzes;
              });
            } else if (state is QuizCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quiz "${state.quiz['title']}" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadQuizzes();
            } else if (state is QuizUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quiz "${state.quiz['title']}" updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadQuizzes();
            } else if (state is QuizDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quiz deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadQuizzes();
            } else if (state is QuizError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${widget.course['title']} - Content'),
              backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
              foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.video_library),
                    text: 'Modules (${_modules.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.quiz),
                    text: 'Quizzes (${_quizzes.length})',
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _selectedTab == 'modules' ? _reorderModules : _reorderQuizzes,
                  icon: const Icon(Icons.sort),
                  tooltip: 'Reorder Content',
                ),
              ],
            ),
            body: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Modules Tab
                  _buildModulesTab(state, isDark),
                  // Quizzes Tab
                  _buildQuizzesTab(isDark),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showCreateOptions,
              backgroundColor: AppTheme.primaryLight,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isQuiz = type == 'quizzes';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isQuiz ? Icons.quiz_outlined : Icons.video_library_outlined,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            isQuiz ? 'No Quizzes Yet' : 'No Modules Yet',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isQuiz 
                ? 'Create your first quiz to start building assessments'
                : 'Create your first module to start building your course',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModulesTab(CourseState state, bool isDark) {
    return Stack(
      children: [
        Column(
          children: [
            // Course Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_library,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.course['title'] ?? 'Course',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_modules.length} modules • ${_getTotalVideos()} videos • ${_formatTotalDuration()}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Modules List
            Expanded(
              child: state.isLoading && _modules.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _modules.isEmpty
                      ? _buildEmptyState(context, 'modules')
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _modules.length,
                          onReorder: _onReorderModules,
                          itemBuilder: (context, index) {
                            final module = _modules[index];
                            return ModuleCard(
                              key: ValueKey(module['id']),
                              module: module,
                              courseId: widget.course['id'],
                              onEdit: () => _editModule(module),
                              onDelete: () => _deleteModule(module),
                            );
                          },
                        ),
            ),
          ],
        ),

        // Loading overlay
        if (state.isLoading && _modules.isNotEmpty)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: HackethosLoadingComponent(
                message: 'Loading modules...',
                size: 60,
                showImage: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuizzesTab(bool isDark) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, quizState) {
        return Stack(
          children: [
            Column(
              children: [
                // Course Info Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.course['title'] ?? 'Course',
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_quizzes.length} quizzes • ${_getTotalMarks()} total marks • ${_formatTotalDuration()} total duration',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quizzes List
                Expanded(
                  child: quizState.isLoading && _quizzes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _quizzes.isEmpty
                          ? _buildEmptyState(context, 'quizzes')
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _quizzes.length,
                              onReorder: _onReorderQuizzes,
                              itemBuilder: (context, index) {
                                final quiz = _quizzes[index];
                                return QuizCard(
                                  key: ValueKey(quiz['id']),
                                  quiz: quiz,
                                  courseId: widget.course['id'],
                                  onEdit: () => _editQuiz(quiz),
                                  onDelete: () => _deleteQuiz(quiz),
                                );
                              },
                            ),
                ),
              ],
            ),

            // Loading overlay
            if (quizState.isLoading && _quizzes.isNotEmpty)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: HackethosLoadingComponent(
                    message: 'Loading quizzes...',
                    size: 60,
                    showImage: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  int _getTotalVideos() {
    return _modules.fold(0, (total, module) => total + ((module['videoCount'] ?? 0) as int));
  }

  int _getTotalMarks() {
    return _quizzes.fold(0, (total, quiz) => total + ((quiz['totalMarks'] ?? 0) as int));
  }

  int _getTotalDuration() {
    return _modules.fold(0, (total, module) => total + ((module['totalDuration'] ?? 0) as int));
  }

  String _formatTotalDuration() {
    final totalSeconds = _getTotalDuration();
    return _formatDuration(totalSeconds);
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

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateOptionsBottomSheet(),
    );
  }

  Widget _buildCreateOptionsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Create New Content',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildCreateOption(
                  icon: Icons.video_library,
                  title: 'Create Module',
                  subtitle: 'Add video content and lessons',
                  onTap: () {
                    Navigator.pop(context);
                    _createModule();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildCreateOption(
                  icon: Icons.quiz,
                  title: 'Create Quiz',
                  subtitle: 'Add interactive quizzes and assessments',
                  onTap: () {
                    Navigator.pop(context);
                    _createQuiz();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _createModule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModuleCreationScreen(
          courseId: widget.course['id'],
          courseTitle: widget.course['title'] ?? 'Course',
        ),
      ),
    );
  }

  void _createQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizCreationScreen(
          courseId: widget.course['id'],
          courseTitle: widget.course['title'] ?? 'Course',
        ),
      ),
    );
  }

  void _editModule(Map<String, dynamic> module) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModuleCreationScreen(
          courseId: widget.course['id'],
          courseTitle: widget.course['title'] ?? 'Course',
          moduleToEdit: module,
        ),
      ),
    );
  }

  void _deleteModule(Map<String, dynamic> module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text('Are you sure you want to delete "${module['title']}"? This will also delete all videos in this module.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CourseBloc>().add(DeleteModule(
                courseId: widget.course['id'],
                moduleId: module['id'],
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderModules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Modules'),
        content: const Text('Long press and drag modules to reorder them. The order will be saved automatically.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _onReorderModules(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _modules.removeAt(oldIndex);
      _modules.insert(newIndex, item);
      
      // Update order for all modules
      for (int i = 0; i < _modules.length; i++) {
        _modules[i]['order'] = i + 1;
      }
    });

    // Save new order to Firebase
    _saveModuleOrder();
  }

  void _onReorderQuizzes(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _quizzes.removeAt(oldIndex);
      _quizzes.insert(newIndex, item);
      
      // Update order for all quizzes
      for (int i = 0; i < _quizzes.length; i++) {
        _quizzes[i]['order'] = i + 1;
      }
    });

    // Save new order to Firebase
    _saveQuizOrder();
  }

  void _saveModuleOrder() {
    for (int i = 0; i < _modules.length; i++) {
      context.read<CourseBloc>().add(UpdateModule(
        courseId: widget.course['id'],
        moduleId: _modules[i]['id'],
        moduleData: {'order': i + 1},
      ));
    }
  }

  void _saveQuizOrder() {
    context.read<QuizBloc>().add(ReorderQuizzes(
      courseId: widget.course['id'],
      reorderedQuizzes: _quizzes,
    ));
  }

  void _editQuiz(Map<String, dynamic> quiz) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizCreationScreen(
          courseId: widget.course['id'],
          courseTitle: widget.course['title'] ?? 'Course',
          quizToEdit: quiz,
        ),
      ),
    );
  }

  void _deleteQuiz(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz['title']}"? This will also delete all questions in this quiz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QuizBloc>().add(DeleteQuiz(
                courseId: widget.course['id'],
                quizId: quiz['id'],
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderQuizzes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Quizzes'),
        content: const Text('Long press and drag quizzes to reorder them. The order will be saved automatically.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
