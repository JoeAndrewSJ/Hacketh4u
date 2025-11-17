import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/models/quiz_model.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository _quizRepository;
  Timer? _quizTimer;

  QuizBloc({
    required QuizRepository quizRepository,
  }) : _quizRepository = quizRepository,
        super(const QuizState()) {
    
    // Quiz Management Events
    on<CreateQuiz>(_onCreateQuiz);
    on<UpdateQuiz>(_onUpdateQuiz);
    on<DeleteQuiz>(_onDeleteQuiz);
    on<LoadCourseQuizzes>(_onLoadCourseQuizzes);
    on<ReorderQuizzes>(_onReorderQuizzes);
    
    // Quiz Taking Events
    on<StartQuiz>(_onStartQuiz);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<CompleteQuiz>(_onCompleteQuiz);
    on<AbandonQuiz>(_onAbandonQuiz);
    on<LoadQuizAttempt>(_onLoadQuizAttempt);
    on<UpdateQuizTimer>(_onUpdateQuizTimer);
    
    // Quiz Results Events
    on<LoadUserQuizResults>(_onLoadUserQuizResults);
    on<LoadCourseQuizResults>(_onLoadCourseQuizResults);
    on<LoadQuizAttempts>(_onLoadQuizAttempts);
    
    // State Management Events
    on<ResetQuizState>(_onResetQuizState);
  }

  @override
  Future<void> close() {
    _quizTimer?.cancel();
    return super.close();
  }

  // ==================== QUIZ MANAGEMENT HANDLERS ====================

  Future<void> _onCreateQuiz(CreateQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Creating quiz: ${event.quiz.title}');
      final createdQuiz = await _quizRepository.createQuiz(event.courseId, event.quiz);
      emit(QuizCreated(quiz: createdQuiz));
      print('QuizBloc: Successfully created quiz: ${createdQuiz.title}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error creating quiz: $e');
    }
  }

  Future<void> _onUpdateQuiz(UpdateQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Updating quiz: ${event.quizId}');
      final updatedQuiz = await _quizRepository.updateQuiz(event.courseId, event.quizId, event.quiz);
      emit(QuizUpdated(quiz: updatedQuiz));
      print('QuizBloc: Successfully updated quiz: ${updatedQuiz.title}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error updating quiz: $e');
    }
  }

  Future<void> _onDeleteQuiz(DeleteQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Deleting quiz: ${event.quizId}');
      await _quizRepository.deleteQuiz(event.courseId, event.quizId);
      emit(QuizDeleted(quizId: event.quizId));
      print('QuizBloc: Successfully deleted quiz: ${event.quizId}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error deleting quiz: $e');
    }
  }

  Future<void> _onLoadCourseQuizzes(LoadCourseQuizzes event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Loading quizzes for course: ${event.courseId}');
      final quizzes = await _quizRepository.getCourseQuizzes(event.courseId);
      emit(QuizzesLoaded(quizzes: quizzes));
      print('QuizBloc: Successfully loaded ${quizzes.length} quizzes for course: ${event.courseId}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error loading course quizzes: $e');
    }
  }

  Future<void> _onReorderQuizzes(ReorderQuizzes event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Reordering quizzes for course: ${event.courseId}');
      // Update order in repository
      for (int i = 0; i < event.reorderedQuizzes.length; i++) {
        final quiz = event.reorderedQuizzes[i];
        final updatedQuiz = QuizModel(
          id: quiz.id,
          courseId: quiz.courseId,
          title: quiz.title,
          description: quiz.description,
          questions: quiz.questions,
          totalMarks: quiz.totalMarks,
          isPremium: quiz.isPremium,
          order: i + 1,
          createdAt: quiz.createdAt,
          updatedAt: DateTime.now(),
          timeLimitMinutes: quiz.timeLimitMinutes,
          passingScore: quiz.passingScore,
          allowRetake: quiz.allowRetake,
          maxAttempts: quiz.maxAttempts,
        );
        await _quizRepository.updateQuiz(event.courseId, quiz.id, updatedQuiz);
      }
      
      emit(QuizzesLoaded(quizzes: event.reorderedQuizzes));
      print('QuizBloc: Successfully reordered quizzes for course: ${event.courseId}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error reordering quizzes: $e');
    }
  }

  // ==================== QUIZ TAKING HANDLERS ====================

  Future<void> _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      print('QuizBloc: Starting quiz: ${event.quizId} for course: ${event.courseId}');

      // Get quiz details
      final quiz = await _quizRepository.getQuizById(event.courseId, event.quizId);
      if (quiz == null) {
        emit(QuizError(error: 'Quiz not found'));
        return;
      }

      // Get previous attempts to check if this is a retake
      QuizAttempt? previousAttempt;
      try {
        final attempts = await _quizRepository.getUserQuizAttempts(event.quizId);
        if (attempts.isNotEmpty) {
          // Get the most recent completed attempt (not abandoned)
          final completedAttempts = attempts.where((a) => !a.isAbandoned && a.completedAt != null).toList();
          if (completedAttempts.isNotEmpty) {
            previousAttempt = completedAttempts.first; // Most recent is first (sorted by date)
            print('QuizBloc: Found previous attempt #${previousAttempt.attemptNumber} with ${previousAttempt.answers.length} answers');
          }
        }
      } catch (e) {
        print('QuizBloc: Could not load previous attempts: $e');
        // Continue without previous attempt
      }

      // Start quiz attempt
      final attempt = await _quizRepository.startQuizAttempt(event.courseId, event.quizId, quiz);

      // Start timer if quiz has time limit
      if (quiz.timeLimitMinutes != null) {
        _startQuizTimer(quiz.timeLimitMinutes! * 60, emit);
      }

      emit(QuizStarted(quiz: quiz, attempt: attempt, previousAttempt: previousAttempt));
      print('QuizBloc: Successfully started quiz: ${quiz.title} (Attempt #${attempt.attemptNumber})');
      if (previousAttempt != null) {
        print('QuizBloc: Previous attempt loaded - user can see their previous answers');
      }
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error starting quiz: $e');
    }
  }

  Future<void> _onAnswerQuestion(AnswerQuestion event, Emitter<QuizState> emit) async {
    try {
      print('QuizBloc: Answering question: ${event.answer.questionId}');
      
      // Save answer to repository
      await _quizRepository.saveQuizAnswer(event.attemptId, event.answer);
      
      // Update current attempt with new answer
      QuizAttempt? currentAttempt;
      if (state is QuizStarted) {
        currentAttempt = (state as QuizStarted).attempt;
      } else if (state is QuizInProgress) {
        currentAttempt = (state as QuizInProgress).attempt;
      } else {
        currentAttempt = state.currentAttempt;
      }
      
      if (currentAttempt != null) {
        // Check if answer already exists for this question to avoid duplicates
        final existingAnswerIndex = currentAttempt.answers.indexWhere(
          (answer) => answer.questionId == event.answer.questionId
        );
        
        final updatedAnswers = List<QuizAttemptAnswer>.from(currentAttempt.answers);
        
        if (existingAnswerIndex >= 0) {
          // Update existing answer
          updatedAnswers[existingAnswerIndex] = event.answer;
          print('QuizBloc: Updated existing answer for question: ${event.answer.questionId}');
        } else {
          // Add new answer
          updatedAnswers.add(event.answer);
          print('QuizBloc: Added new answer for question: ${event.answer.questionId}');
        }
        
        final totalMarksObtained = updatedAnswers.fold<int>(0, (sum, answer) => sum + answer.marksObtained);
        
        final updatedAttempt = QuizAttempt(
          id: currentAttempt.id,
          quizId: currentAttempt.quizId,
          courseId: currentAttempt.courseId,
          userId: currentAttempt.userId,
          answers: updatedAnswers,
          totalMarks: currentAttempt.totalMarks,
          marksObtained: totalMarksObtained,
          percentage: (totalMarksObtained / currentAttempt.totalMarks) * 100,
          isPassed: false, // Will be calculated on completion
          startedAt: currentAttempt.startedAt,
          completedAt: currentAttempt.completedAt,
          attemptNumber: currentAttempt.attemptNumber,
          timeSpentPerQuestion: {
            ...currentAttempt.timeSpentPerQuestion,
            event.answer.questionId: event.answer.timeSpentSeconds ?? 0,
          },
          isAbandoned: currentAttempt.isAbandoned,
        );

        // Maintain the current state type while updating the attempt
        if (state is QuizStarted) {
          emit(QuizStarted(
            quiz: (state as QuizStarted).quiz,
            attempt: updatedAttempt,
          ));
        } else if (state is QuizInProgress) {
          final quizInProgressState = state as QuizInProgress;
          emit(QuizInProgress(
            quiz: quizInProgressState.quiz,
            attempt: updatedAttempt,
            currentQuestionIndex: quizInProgressState.currentQuestionIndex,
            remainingTime: quizInProgressState.remainingTime,
          ));
        } else {
          // Fallback to copyWith for other states
          emit(state.copyWith(
            currentAttempt: updatedAttempt,
            currentQuestionIndex: state.currentQuestionIndex + 1,
          ));
        }
      }
      
      print('QuizBloc: Successfully answered question: ${event.answer.questionId}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error answering question: $e');
    }
  }

  Future<void> _onCompleteQuiz(CompleteQuiz event, Emitter<QuizState> emit) async {
    try {
      print('QuizBloc: Completing quiz attempt: ${event.attemptId}');
      
      // Get current attempt from the correct state
      QuizAttempt? currentAttempt;
      QuizModel? currentQuiz;
      
      if (state is QuizStarted) {
        currentAttempt = (state as QuizStarted).attempt;
        currentQuiz = (state as QuizStarted).quiz;
      } else if (state is QuizInProgress) {
        currentAttempt = (state as QuizInProgress).attempt;
        currentQuiz = (state as QuizInProgress).quiz;
      } else {
        currentAttempt = state.currentAttempt;
        currentQuiz = state.currentQuiz;
      }
      
      if (currentAttempt == null) {
        emit(QuizError(error: 'No active quiz attempt found'));
        return;
      }
      
      if (currentQuiz == null) {
        emit(QuizError(error: 'No active quiz found'));
        return;
      }

      // Complete quiz in repository
      final completedAttempt = await _quizRepository.completeQuizAttempt(event.attemptId, currentAttempt.answers);
      
      // Stop timer
      _quizTimer?.cancel();
      
      emit(QuizCompleted(attempt: completedAttempt, quiz: currentQuiz));
      print('QuizBloc: Successfully completed quiz with score: ${completedAttempt.percentage.toStringAsFixed(1)}%');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error completing quiz: $e');
    }
  }

  Future<void> _onAbandonQuiz(AbandonQuiz event, Emitter<QuizState> emit) async {
    try {
      print('QuizBloc: Abandoning quiz attempt: ${event.attemptId}');
      
      await _quizRepository.abandonQuizAttempt(event.attemptId);
      
      // Stop timer
      _quizTimer?.cancel();
      
      emit(QuizAbandoned(attemptId: event.attemptId));
      print('QuizBloc: Successfully abandoned quiz attempt: ${event.attemptId}');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error abandoning quiz: $e');
    }
  }

  Future<void> _onLoadQuizAttempt(LoadQuizAttempt event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Loading quiz attempt: ${event.attemptId}');
      // This would require a method in repository to get attempt by ID
      // For now, we'll emit loading state
      emit(state.copyWith(isLoading: false));
      print('QuizBloc: Quiz attempt loading not yet implemented');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error loading quiz attempt: $e');
    }
  }

  Future<void> _onUpdateQuizTimer(UpdateQuizTimer event, Emitter<QuizState> emit) async {
    emit(state.copyWith(remainingTime: event.remainingSeconds));
    
    if (event.remainingSeconds <= 0) {
      // Time's up - auto-submit quiz
      final currentAttempt = state.currentAttempt;
      if (currentAttempt != null) {
        add(CompleteQuiz(attemptId: currentAttempt.id));
      }
    }
  }

  // ==================== QUIZ RESULTS HANDLERS ====================

  Future<void> _onLoadUserQuizResults(LoadUserQuizResults event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Loading quiz results for quiz: ${event.quizId}');
      final results = await _quizRepository.getUserQuizAttempts(event.quizId);
      emit(QuizAttemptsLoaded(attempts: results));
      print('QuizBloc: Successfully loaded ${results.length} quiz attempts');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error loading quiz results: $e');
    }
  }

  Future<void> _onLoadCourseQuizResults(LoadCourseQuizResults event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Loading quiz results for course: ${event.courseId}');
      final results = await _quizRepository.getCourseQuizResults(event.courseId);
      emit(QuizResultsLoaded(results: results));
      print('QuizBloc: Successfully loaded ${results.length} quiz results for course');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error loading course quiz results: $e');
    }
  }

  Future<void> _onLoadQuizAttempts(LoadQuizAttempts event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      print('QuizBloc: Loading quiz attempts for quiz: ${event.quizId}');
      final attempts = await _quizRepository.getUserQuizAttempts(event.quizId);
      emit(QuizAttemptsLoaded(attempts: attempts));
      print('QuizBloc: Successfully loaded ${attempts.length} quiz attempts');
    } catch (e) {
      emit(QuizError(error: e.toString()));
      print('QuizBloc: Error loading quiz attempts: $e');
    }
  }

  // ==================== STATE MANAGEMENT HANDLERS ====================

  Future<void> _onResetQuizState(ResetQuizState event, Emitter<QuizState> emit) async {
    print('QuizBloc: Resetting quiz state');
    _quizTimer?.cancel();
    emit(const QuizState());
  }

  // ==================== HELPER METHODS ====================

  void _startQuizTimer(int totalSeconds, Emitter<QuizState> emit) {
    _quizTimer?.cancel();
    
    int remainingSeconds = totalSeconds;
    
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      add(UpdateQuizTimer(remainingSeconds: remainingSeconds));
      
      if (remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }
}
