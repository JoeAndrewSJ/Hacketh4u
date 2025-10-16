import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../../data/models/quiz_model.dart';
import '../../widgets/quiz/quiz_question_widget.dart';
import '../../widgets/quiz/quiz_timer_widget.dart';
import '../../widgets/quiz/quiz_progress_widget.dart';
import '../../widgets/quiz/quiz_navigation_widget.dart';
import 'quiz_result_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  final String courseId;
  final String quizId;
  final QuizModel quiz;

  const QuizTakingScreen({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.quiz,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  Map<String, int> _answers = {};
  Map<String, DateTime> _questionStartTimes = {};
  Set<String> _answeredQuestions = {};
  bool _isQuizStarted = false;
  int? _currentQuestionSelection; // Track current question's selection separately

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  void _startQuiz() {
    context.read<QuizBloc>().add(StartQuiz(
      courseId: widget.courseId,
      quizId: widget.quizId,
    ));

    _questionStartTimes[widget.quiz.questions[_currentQuestionIndex].id] = DateTime.now();
    setState(() {
      _isQuizStarted = true;
      _resetCurrentQuestionSelection(); // Start with clean UI
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () => _showExitConfirmation(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(
            widget.quiz.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppTheme.backgroundLight,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          centerTitle: true,
          actions: [
            if (widget.quiz.timeLimitMinutes != null)
              BlocBuilder<QuizBloc, QuizState>(
                builder: (context, state) {
                  if (state is QuizInProgress) {
                    return QuizTimerWidget(
                      remainingSeconds: state.remainingTime,
                      totalSeconds: widget.quiz.timeLimitMinutes! * 60,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        body: BlocListener<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizStarted) {
              // Only reset to first question if we're at the very beginning
              // Don't reset if we're already in the middle of a quiz (answering questions)
              if (_currentQuestionIndex == 0 && !_isQuizStarted) {
                setState(() {
                  _currentQuestionIndex = 0;
                  _isQuizStarted = true;
                });
              }
            } else if (state is QuizCompleted) {
              _navigateToResult(state.attempt);
            } else if (state is QuizAbandoned) {
              Navigator.pop(context);
            } else if (state is QuizError) {
              _showErrorDialog(state.error);
            }
          },
          child: BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state.isLoading) {
                return _buildLoadingState(isDark);
              }

              if (state is QuizStarted || state is QuizInProgress) {
                return _buildQuizContent(state, isDark);
              }

              if (state is QuizCompleted) {
                // Show loading state while navigating to results
                return _buildLoadingState(isDark);
              }

              if (state is QuizError) {
                return _buildErrorState(state.error, isDark);
              }

              return _buildErrorState(state.errorMessage ?? 'Unknown error', isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    // Check if this is a completion state
    final currentState = context.read<QuizBloc>().state;
    final isLoadingCompletion = currentState is QuizCompleted;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            isLoadingCompletion ? 'Generating results...' : 'Preparing quiz...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(QuizState state, bool isDark) {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;
    
    // Use the current question selection for UI display
    // This ensures clean state when navigating between questions
    final selectedAnswer = _currentQuestionSelection;
    
    return Column(
      children: [
        // Progress Header
        QuizProgressWidget(
          currentQuestion: _currentQuestionIndex + 1,
          totalQuestions: widget.quiz.questions.length,
          isDark: isDark,
        ),
        
        // Question Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                QuizQuestionWidget(
                  // Use a unique key combining question ID and current index
                  // This forces the widget to rebuild completely when question changes
                  key: ValueKey('question_${currentQuestion.id}_$_currentQuestionIndex'),
                  question: currentQuestion,
                  selectedAnswerIndex: selectedAnswer,
                  onAnswerSelected: (answerIndex) => _selectAnswer(currentQuestion.id, answerIndex),
                  isDark: isDark,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        // Navigation Buttons
        QuizNavigationWidget(
          currentQuestion: _currentQuestionIndex + 1,
          totalQuestions: widget.quiz.questions.length,
          isLastQuestion: isLastQuestion,
          hasAnswer: _answeredQuestions.contains(currentQuestion.id), // Check if question has been answered
          onPrevious: _goToPreviousQuestion,
          onNext: _goToNextQuestion,
          onSubmit: _submitQuiz,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Quiz',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(String questionId, int answerIndex) {
    setState(() {
      _answers[questionId] = answerIndex;
      _answeredQuestions.add(questionId);
      _currentQuestionSelection = answerIndex; // Update current question selection
    });
    
    // Save the answer immediately to the backend
    _saveAnswerForQuestion(questionId, answerIndex);
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _resetCurrentQuestionSelection(); // Reset selection for clean UI
      });
      _recordQuestionStartTime();
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _resetCurrentQuestionSelection(); // Reset selection for clean UI
      });
      _recordQuestionStartTime();
    }
  }
  
  void _resetCurrentQuestionSelection() {
    // Reset the current question selection to show clean UI
    // The stored answers are preserved in _answers map
    _currentQuestionSelection = null;
  }

  void _recordQuestionStartTime() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    if (!_questionStartTimes.containsKey(currentQuestion.id)) {
      _questionStartTimes[currentQuestion.id] = DateTime.now();
    }
  }

  void _saveCurrentAnswer() {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _answers[currentQuestion.id];
    
    if (selectedAnswer != null) {
      _saveAnswerForQuestion(currentQuestion.id, selectedAnswer);
    }
  }
  
  void _saveAnswerForQuestion(String questionId, int answerIndex) {
    final question = widget.quiz.questions.firstWhere((q) => q.id == questionId);
    final startTime = _questionStartTimes[questionId];
    final timeSpent = startTime != null 
        ? DateTime.now().difference(startTime).inSeconds 
        : 0;

    final isCorrect = answerIndex == question.correctAnswerIndex;
    final marksObtained = isCorrect ? question.marks : 0;

    final answer = QuizAttemptAnswer(
      questionId: questionId,
      selectedAnswerIndex: answerIndex,
      isCorrect: isCorrect,
      marksObtained: marksObtained,
      answeredAt: DateTime.now(),
      timeSpentSeconds: timeSpent,
    );

    final currentState = context.read<QuizBloc>().state;
    String? attemptId;
    
    if (currentState is QuizStarted) {
      attemptId = currentState.attempt.id;
    } else if (currentState is QuizInProgress) {
      attemptId = currentState.attempt.id;
    }

    if (attemptId != null) {
      context.read<QuizBloc>().add(AnswerQuestion(
        attemptId: attemptId,
        answer: answer,
      ));
    }
  }

  void _submitQuiz() {
    // Get attempt ID before saving current answer (to avoid state changes)
    final currentState = context.read<QuizBloc>().state;
    String? attemptId;
    
    print('QuizTakingScreen: Current state type: ${currentState.runtimeType}');
    if (currentState is QuizStarted) {
      print('QuizTakingScreen: QuizStarted attempt: ${currentState.attempt.id}');
    } else if (currentState is QuizInProgress) {
      print('QuizTakingScreen: QuizInProgress attempt: ${currentState.attempt.id}');
    }
    
    if (currentState is QuizStarted) {
      attemptId = currentState.attempt.id;
      print('QuizTakingScreen: Got attempt ID from QuizStarted: $attemptId');
    } else if (currentState is QuizInProgress) {
      attemptId = currentState.attempt.id;
      print('QuizTakingScreen: Got attempt ID from QuizInProgress: $attemptId');
    }
    
    if (attemptId == null) {
      print('QuizTakingScreen: No active quiz attempt found for submission');
      print('QuizTakingScreen: Current state: $currentState');
      return;
    }
    
    // Save current answer first
    _saveCurrentAnswer();
    
    // Submit the quiz
    print('QuizTakingScreen: Submitting quiz with attempt ID: $attemptId');
    context.read<QuizBloc>().add(CompleteQuiz(attemptId: attemptId));
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit the quiz? Your progress will be saved, but you won\'t be able to continue from where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit Quiz'),
          ),
        ],
      ),
    );

    if (result == true) {
      final currentState = context.read<QuizBloc>().state;
      String? attemptId;
      
      if (currentState is QuizStarted) {
        attemptId = currentState.attempt.id;
      } else if (currentState is QuizInProgress) {
        attemptId = currentState.attempt.id;
      }

      if (attemptId != null) {
        context.read<QuizBloc>().add(AbandonQuiz(attemptId: attemptId));
      }
      return true;
    }

    return false;
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(QuizAttempt attempt) {
    print('QuizTakingScreen: Navigating to result screen with attempt: ${attempt.id}');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          courseId: widget.courseId,
          quiz: widget.quiz,
          attempt: attempt,
        ),
      ),
    );
  }
}