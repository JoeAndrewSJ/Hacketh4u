import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';

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
  
  bool _isPremium = false;
  List<Map<String, dynamic>> _questions = [];
  int _questionCounter = 1;

  @override
  void initState() {
    super.initState();
    if (widget.quizToEdit != null) {
      _loadQuizData();
    }
  }

  void _loadQuizData() {
    final quiz = widget.quizToEdit!;
    _titleController.text = quiz['title'] ?? '';
    _descriptionController.text = quiz['description'] ?? '';
    _totalMarksController.text = quiz['totalMarks']?.toString() ?? '';
    _isPremium = quiz['isPremium'] ?? false;
    final questionsData = quiz['questions'] as List<dynamic>? ?? [];
    _questions = questionsData.map((question) => question as Map<String, dynamic>).toList();
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
          actions: [
            if (_questions.isNotEmpty)
              IconButton(
                onPressed: _saveQuiz,
                icon: const Icon(Icons.save),
                tooltip: 'Save Quiz',
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
                // Quiz Basic Info
                _buildBasicInfoSection(isDark),
                const SizedBox(height: 24),
                
                // Premium Toggle
                _buildPremiumToggle(isDark),
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
          ...(question['options'] as List<dynamic>? ?? []).map((option) => option as Map<String, dynamic>).toList().asMap().entries.map((optionEntry) {
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

    final quizData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'totalMarks': int.parse(_totalMarksController.text.trim()),
      'isPremium': _isPremium,
      'questions': _questions,
      'order': widget.quizToEdit?['order'] ?? 1,
    };

    if (widget.quizToEdit != null) {
      context.read<QuizBloc>().add(UpdateQuiz(
        courseId: widget.courseId,
        quizId: widget.quizToEdit!['id'],
        quizData: quizData,
      ));
    } else {
      context.read<QuizBloc>().add(CreateQuiz(
        courseId: widget.courseId,
        quizData: quizData,
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
    _questionController.text = question['question'] ?? '';
    final optionsData = question['options'] as List<dynamic>? ?? [];
    _options = optionsData.map((option) => option as Map<String, dynamic>).toList();
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
