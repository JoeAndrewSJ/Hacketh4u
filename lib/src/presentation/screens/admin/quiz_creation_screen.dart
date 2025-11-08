import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../core/di/service_locator.dart';

class QuizCreationScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Map<String, dynamic>? quizToEdit;

  const QuizCreationScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.quizToEdit,
  });

  @override
  State<QuizCreationScreen> createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalMarksController = TextEditingController();

  // Helper method for safe timestamp conversion
  DateTime? _safeTimestampConversion(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
  
  bool _isPremium = false;
  List<Map<String, dynamic>> _questions = [];
  int _questionCounter = 1;

  // Module selection
  List<Map<String, dynamic>> _modules = [];
  String? _selectedModuleId;
  bool _isLoadingModules = true;

  // Quiz Settings
  int _maxAttempts = 3;
  bool _allowRetake = true;
  bool _showAnswersAfterCompletion = true;
  int _showAnswersAfterAttempts = 1;

  @override
  void initState() {
    super.initState();
    _fetchModules();
    if (widget.quizToEdit != null) {
      _loadQuizData();
    }
  }

  Future<void> _fetchModules() async {
    try {
      final courseRepository = sl<CourseRepository>();
      // Modules are stored in a separate collection, not in the course document
      final modules = await courseRepository.getCourseModules(widget.courseId);

      print('QuizCreationScreen: Fetched ${modules.length} modules for course ${widget.courseId}');
      for (var module in modules) {
        print('  - Module: ${module['title']} (ID: ${module['id']}, Order: ${module['order']})');
      }

      setState(() {
        _modules = modules;
        _isLoadingModules = false;
      });
    } catch (e) {
      print('Error fetching modules: $e');
      setState(() {
        _isLoadingModules = false;
      });
    }
  }

  void _loadQuizData() {
    final quiz = widget.quizToEdit!;
    _titleController.text = quiz['title'] ?? '';
    _descriptionController.text = quiz['description'] ?? '';
    _totalMarksController.text = quiz['totalMarks']?.toString() ?? '';
    _isPremium = quiz['isPremium'] ?? false;
    _selectedModuleId = quiz['moduleId']?.toString();

    // Load quiz settings with safe defaults for backward compatibility
    _maxAttempts = (quiz['maxAttempts'] as int?) ?? 3;
    _allowRetake = (quiz['allowRetake'] as bool?) ?? true;
    _showAnswersAfterCompletion = (quiz['showAnswersAfterCompletion'] as bool?) ?? true;
    _showAnswersAfterAttempts = (quiz['showAnswersAfterAttempts'] as int?) ?? 1;

    final questionsData = quiz['questions'] as List<dynamic>? ?? [];
    
    // Debug: Print the questions data to see its structure
    print('QuizCreationScreen: Loading quiz data:');
    print('Quiz title: ${quiz['title']}');
    print('Questions data: $questionsData');
    
    _questions = questionsData.map((question) {
      // Handle different question data formats
      if (question is Map<String, dynamic>) {
        print('Question is Map: $question');
        
        // If this is a QuizQuestion from Firestore (has correctAnswerIndex), convert it to UI format
        if (question.containsKey('correctAnswerIndex') && question.containsKey('questionText')) {
          final correctAnswerIndex = question['correctAnswerIndex'] as int? ?? 0;
          final options = question['options'] as List<dynamic>? ?? [];
          
          // Convert options to UI format with isCorrect flags
          final uiOptions = options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return {
              'text': option.toString(),
              'isCorrect': index == correctAnswerIndex,
            };
          }).toList();
          
          return {
            'question': question['questionText'],
            'options': uiOptions,
            'id': question['id'],
            'explanation': question['explanation'],
            'marks': question['marks'],
            'timeLimitSeconds': question['timeLimitSeconds'],
          };
        } else {
          // This is already in UI format
          return question;
        }
      } else if (question is String) {
        print('Question is String: $question');
        // Convert string to Map format
        return {
          'question': question,
          'options': [],
        };
      } else {
        print('Question is other type: $question (${question.runtimeType})');
        // Try to convert to Map
        return {
          'question': question.toString(),
          'options': [],
        };
      }
    }).toList();
    
    _questionCounter = _questions.length + 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state is QuizCreated || state is QuizUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.quizToEdit != null 
                    ? 'Quiz updated successfully!' 
                    : 'Quiz created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizToEdit != null ? 'Edit Quiz' : 'Create Quiz'),
          backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
          foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,

        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quiz Basic Info
                _buildBasicInfoSection(isDark),
                const SizedBox(height: 24),

                // Module Selection
                _buildModuleSelectionSection(isDark),
                const SizedBox(height: 24),

                // Premium Toggle
                _buildPremiumToggle(isDark),
                const SizedBox(height: 24),

                // Quiz Settings Section
                _buildQuizSettingsSection(isDark),
                const SizedBox(height: 24),

                // Questions Section
                _buildQuestionsSection(isDark),
                const SizedBox(height: 24),
                
                // Add Question Button
                _buildAddQuestionButton(isDark),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
        floatingActionButton: _questions.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _saveQuiz,
                backgroundColor: AppTheme.primaryLight,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  widget.quizToEdit != null ? 'Update Quiz' : 'Create Quiz',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Information',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'Enter quiz title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quiz title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter quiz description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalMarksController,
              decoration: const InputDecoration(
                labelText: 'Total Marks',
                hintText: 'Enter total marks',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter total marks';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSelectionSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Module Assignment',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingModules)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_modules.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No modules found in this course. The quiz will not be assigned to any specific module.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedModuleId,
                decoration: const InputDecoration(
                  labelText: 'Select Module (Optional)',
                  hintText: 'Choose a module for this quiz',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'No Module (General Quiz)',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ..._modules.map((module) {
                    final moduleId = module['id']?.toString() ?? '';
                    final moduleName = module['title']?.toString() ?? 'Unnamed Module';
                    final moduleOrder = module['order']?.toString() ?? '';

                    return DropdownMenuItem<String>(
                      value: moduleId,
                      child: Text('Module $moduleOrder: $moduleName'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedModuleId = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumToggle(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isPremium ? Icons.star : Icons.star_border,
              color: _isPremium ? Colors.amber : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Quiz',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isPremium 
                        ? 'This quiz is available only to premium users'
                        : 'This quiz is available to all users',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isPremium,
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                });
              },
              activeColor: AppTheme.primaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSettingsSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quiz Settings',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Allow Retake Toggle
            Row(
              children: [
                Icon(
                  _allowRetake ? Icons.replay : Icons.replay_outlined,
                  color: _allowRetake ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allow Retake',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _allowRetake
                            ? 'Students can retake this quiz'
                            : 'One-time attempt only',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _allowRetake,
                  onChanged: (value) {
                    setState(() {
                      _allowRetake = value;
                      if (!value) {
                        _maxAttempts = 1;
                      }
                    });
                  },
                  activeColor: AppTheme.primaryLight,
                ),
              ],
            ),

            if (_allowRetake) ...[
              const SizedBox(height: 20),
              // Max Attempts Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.numbers,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Maximum Attempts: $_maxAttempts',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '1',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _maxAttempts.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_maxAttempts',
                          activeColor: AppTheme.primaryLight,
                          onChanged: (value) {
                            setState(() {
                              _maxAttempts = value.toInt();
                              // Ensure showAnswersAfterAttempts doesn't exceed maxAttempts
                              if (_showAnswersAfterAttempts > _maxAttempts) {
                                _showAnswersAfterAttempts = _maxAttempts;
                              }
                            });
                          },
                        ),
                      ),
                      Text(
                        '10',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            Divider(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 20),

            // Show Answers After Completion Toggle
            Row(
              children: [
                Icon(
                  _showAnswersAfterCompletion ? Icons.visibility : Icons.visibility_off,
                  color: _showAnswersAfterCompletion ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show Answers After Completion',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _showAnswersAfterCompletion
                            ? 'Students can view correct answers'
                            : 'Answers will be hidden',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showAnswersAfterCompletion,
                  onChanged: (value) {
                    setState(() {
                      _showAnswersAfterCompletion = value;
                    });
                  },
                  activeColor: AppTheme.primaryLight,
                ),
              ],
            ),

            if (_showAnswersAfterCompletion) ...[
              const SizedBox(height: 20),
              // Show Answers After N Attempts Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show Answers After Attempt: $_showAnswersAfterAttempts',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Students can see answers after completing $_showAnswersAfterAttempts ${_showAnswersAfterAttempts == 1 ? "attempt" : "attempts"}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '1',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _showAnswersAfterAttempts.toDouble(),
                          min: 1,
                          max: _maxAttempts.toDouble(),
                          divisions: _maxAttempts > 1 ? _maxAttempts - 1 : null,
                          label: '$_showAnswersAfterAttempts',
                          activeColor: AppTheme.primaryLight,
                          onChanged: (value) {
                            setState(() {
                              _showAnswersAfterAttempts = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(
                        '$_maxAttempts',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Questions (${_questions.length})',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_questions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No questions added yet',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first question to get started',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionCard(question, index, isDark);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index, bool isDark) {
    // Debug: Print question data
    print('_buildQuestionCard: Building card for question $index: $question');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _editQuestion(index),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit Question',
              ),
              IconButton(
                onPressed: () => _deleteQuestion(index),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Delete Question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question['question'] ?? '',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...(question['options'] as List<dynamic>? ?? []).map((option) {
            // Handle different option data formats
            if (option is Map<String, dynamic>) {
              return option;
            } else if (option is String) {
              // Convert string to Map format
              return {
                'text': option,
                'isCorrect': false,
              };
            } else {
              // Try to convert to Map
              return {
                'text': option.toString(),
                'isCorrect': false,
              };
            }
          }).toList().asMap().entries.map((optionEntry) {
            final optionIndex = optionEntry.key;
            final option = optionEntry.value;
            final isCorrect = option['isCorrect'] ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${String.fromCharCode(65 + optionIndex)}. ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      option['text'] ?? '',
                      style: TextStyle(
                        color: isCorrect ? Colors.green[800] : Colors.grey[700],
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddQuestionButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionCreationScreen(
          questionNumber: _questionCounter,
          onSave: (question) {
            setState(() {
              _questions.add(question);
              _questionCounter++;
            });
          },
        ),
      ),
    );
  }

  void _editQuestion(int index) {
    // Debug: Print the question being edited
    print('QuizCreationScreen: Editing question at index $index:');
    print('Question data: ${_questions[index]}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionCreationScreen(
          questionNumber: index + 1,
          questionToEdit: _questions[index],
          onSave: (question) {
            setState(() {
              _questions[index] = question;
            });
          },
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _questions.removeAt(index);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveQuiz() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Debug: Print the questions being saved
    print('QuizCreationScreen: Saving quiz with ${_questions.length} questions:');
    for (int i = 0; i < _questions.length; i++) {
      print('Question $i: ${_questions[i]}');
    }

    // Convert questions to QuizQuestion objects
    final quizQuestions = <QuizQuestion>[];
    
    for (int questionIndex = 0; questionIndex < _questions.length; questionIndex++) {
      final q = _questions[questionIndex];
      
      // Handle the field name mismatch between QuestionCreationScreen and QuizQuestion
      final questionText = q['questionText'] ?? q['question'] ?? '';
      final options = q['options'] as List<dynamic>? ?? [];
      
      // Find the correct answer index from the options
      int correctAnswerIndex = 0;
      print('QuizCreationScreen: Processing question options: $options');
      for (int i = 0; i < options.length; i++) {
        print('Option $i: ${options[i]} (isCorrect: ${options[i]['isCorrect']})');
        if (options[i]['isCorrect'] == true) {
          correctAnswerIndex = i;
          print('Found correct answer at index: $i');
          break;
        }
      }
      
      // Generate unique ID if not present
      String questionId = q['id'] ?? '';
      if (questionId.isEmpty) {
        questionId = '${DateTime.now().millisecondsSinceEpoch}_${questionIndex}_${(1000 + questionIndex * 1000)}';
      }
      
      final quizQuestion = QuizQuestion(
        id: questionId,
        questionText: questionText,
        options: options.map((opt) => opt['text']?.toString() ?? opt.toString()).toList(),
        correctAnswerIndex: correctAnswerIndex,
        explanation: q['explanation'],
        marks: q['marks'] ?? 1,
        timeLimitSeconds: q['timeLimitSeconds'],
      );
      
      // Debug: Print the created QuizQuestion
      print('Created QuizQuestion: ${quizQuestion.questionText}');
      print('Options: ${quizQuestion.options}');
      print('Correct Answer Index: ${quizQuestion.correctAnswerIndex}');
      
      quizQuestions.add(quizQuestion);
    }

    // Debug: Print the quiz data being saved
    print('QuizCreationScreen: Saving quiz with data:');
    print('ID: ${widget.quizToEdit?['id'] ?? 'NEW'}');
    print('Title: ${_titleController.text.trim()}');
    print('CreatedAt type: ${widget.quizToEdit?['createdAt'].runtimeType}');
    print('CreatedAt value: ${widget.quizToEdit?['createdAt']}');
    
    final quiz = QuizModel(
      id: widget.quizToEdit?['id'] ?? '',
      courseId: widget.courseId,
      moduleId: _selectedModuleId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      questions: quizQuestions,
      totalMarks: int.parse(_totalMarksController.text.trim()),
      isPremium: _isPremium,
      order: widget.quizToEdit?['order'] ?? 1,
      createdAt: _safeTimestampConversion(widget.quizToEdit?['createdAt']),
      updatedAt: DateTime.now(),
      timeLimitMinutes: null, // Can be added later
      passingScore: 60, // Default passing score
      allowRetake: _allowRetake,
      maxAttempts: _maxAttempts,
      showAnswersAfterCompletion: _showAnswersAfterCompletion,
      showAnswersAfterAttempts: _showAnswersAfterAttempts,
    );

    if (widget.quizToEdit != null) {
      context.read<QuizBloc>().add(UpdateQuiz(
        courseId: widget.courseId,
        quizId: widget.quizToEdit!['id'],
        quiz: quiz,
      ));
    } else {
      context.read<QuizBloc>().add(CreateQuiz(
        courseId: widget.courseId,
        quiz: quiz,
      ));
    }
  }
}

class QuestionCreationScreen extends StatefulWidget {
  final int questionNumber;
  final Map<String, dynamic>? questionToEdit;
  final Function(Map<String, dynamic>) onSave;

  const QuestionCreationScreen({
    super.key,
    required this.questionNumber,
    this.questionToEdit,
    required this.onSave,
  });

  @override
  State<QuestionCreationScreen> createState() => _QuestionCreationScreenState();
}

class _QuestionCreationScreenState extends State<QuestionCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  List<Map<String, dynamic>> _options = [];
  int _optionCounter = 1;

  @override
  void initState() {
    super.initState();
    if (widget.questionToEdit != null) {
      _loadQuestionData();
    } else {
      _addOption(); // Add first option by default
    }
  }

  void _loadQuestionData() {
    final question = widget.questionToEdit!;
    // Handle both 'question' and 'questionText' field names
    _questionController.text = question['question'] ?? question['questionText'] ?? '';
    final optionsData = question['options'] as List<dynamic>? ?? [];
    final correctAnswerIndex = question['correctAnswerIndex'] as int? ?? 0;
    
    // Debug: Print the question data being loaded
    print('QuestionCreationScreen: Loading question data:');
    print('Question text: ${question['question'] ?? question['questionText']}');
    print('Options: $optionsData');
    print('Correct answer index: $correctAnswerIndex');
    
    // Convert options to the expected format if they're simple strings
    _options = optionsData.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      
      if (option is String) {
        return {
          'text': option, 
          'isCorrect': index == correctAnswerIndex
        };
      } else if (option is Map<String, dynamic>) {
        // If it's already a map, preserve the isCorrect value or set it based on correctAnswerIndex
        final isCorrect = option['isCorrect'] ?? (index == correctAnswerIndex);
        return {
          'text': option['text'] ?? option.toString(),
          'isCorrect': isCorrect
        };
      } else {
        return {
          'text': option.toString(), 
          'isCorrect': index == correctAnswerIndex
        };
      }
    }).toList();
    
    // Debug: Print the converted options
    print('QuestionCreationScreen: Converted options: $_options');
    
    // Debug: Print each option individually
    for (int i = 0; i < _options.length; i++) {
      print('Option $i: ${_options[i]} (isCorrect: ${_options[i]['isCorrect']})');
    }
    
    _optionCounter = _options.length + 1;
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${widget.questionNumber}'),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
        actions: [
          TextButton(
            onPressed: _saveQuestion,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Text
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question Text',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your question',
                          hintText: 'What is your question?',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Options Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Options (${_options.length})',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Option'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return _buildOptionCard(option, index, isDark);
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _options.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _saveQuestion,
              backgroundColor: AppTheme.primaryLight,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                widget.questionToEdit != null ? 'Update Question' : 'Save Question',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, int index, bool isDark) {
    final controller = TextEditingController(text: option['text'] ?? '');
    final isCorrect = option['isCorrect'] ?? false;
    
    // Debug: Print option data
    print('_buildOptionCard: Building option $index: $option');
    print('_buildOptionCard: isCorrect: $isCorrect');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey[300]!,
          width: isCorrect ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCorrect ? Colors.green.withOpacity(0.05) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isCorrect ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter option text',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    _options[index]['text'] = value;
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter option text';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _toggleCorrectOption(index),
                icon: Icon(
                  isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCorrect ? Colors.green : Colors.grey,
                ),
                tooltip: isCorrect ? 'Correct Answer' : 'Mark as Correct',
              ),
              IconButton(
                onPressed: () => _removeOption(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove Option',
              ),
            ],
          ),
          if (isCorrect)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Correct Answer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addOption() {
    setState(() {
      _options.add({
        'text': '',
        'isCorrect': false,
      });
      _optionCounter++;
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 options are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _options.removeAt(index);
    });
  }

  void _toggleCorrectOption(int index) {
    setState(() {
      // First, set all options to incorrect
      for (int i = 0; i < _options.length; i++) {
        _options[i]['isCorrect'] = false;
      }
      // Then set the selected option as correct
      _options[index]['isCorrect'] = true;
    });
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one option is marked as correct
    final hasCorrectOption = _options.any((option) => option['isCorrect'] == true);
    if (!hasCorrectOption) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark at least one option as correct'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final question = {
      'question': _questionController.text.trim(),
      'options': _options,
    };

    widget.onSave(question);
    Navigator.pop(context);
  }
}
