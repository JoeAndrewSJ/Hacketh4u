import 'package:equatable/equatable.dart';
import '../../../data/models/quiz_model.dart';

class QuizState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<QuizModel> quizzes;
  final QuizModel? currentQuiz;
  final QuizAttempt? currentAttempt;
  final List<QuizAttempt> quizAttempts;
  final List<QuizResultSummary> quizResults;
  final int currentQuestionIndex;
  final int remainingTime;
  final bool isQuizActive;
  final bool isQuizCompleted;

  const QuizState({
    this.isLoading = false,
    this.errorMessage,
    this.quizzes = const [],
    this.currentQuiz,
    this.currentAttempt,
    this.quizAttempts = const [],
    this.quizResults = const [],
    this.currentQuestionIndex = 0,
    this.remainingTime = 0,
    this.isQuizActive = false,
    this.isQuizCompleted = false,
  });

  QuizState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<QuizModel>? quizzes,
    QuizModel? currentQuiz,
    QuizAttempt? currentAttempt,
    List<QuizAttempt>? quizAttempts,
    List<QuizResultSummary>? quizResults,
    int? currentQuestionIndex,
    int? remainingTime,
    bool? isQuizActive,
    bool? isQuizCompleted,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      quizzes: quizzes ?? this.quizzes,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      quizResults: quizResults ?? this.quizResults,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      isQuizActive: isQuizActive ?? this.isQuizActive,
      isQuizCompleted: isQuizCompleted ?? this.isQuizCompleted,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        quizzes,
        currentQuiz,
        currentAttempt,
        quizAttempts,
        quizResults,
        currentQuestionIndex,
        remainingTime,
        isQuizActive,
        isQuizCompleted,
      ];
}

// ==================== QUIZ MANAGEMENT STATES ====================

class QuizCreated extends QuizState {
  final QuizModel quiz;

  const QuizCreated({required this.quiz});

  @override
  List<Object?> get props => [quiz];
}

class QuizUpdated extends QuizState {
  final QuizModel quiz;

  const QuizUpdated({required this.quiz});

  @override
  List<Object?> get props => [quiz];
}

class QuizDeleted extends QuizState {
  final String quizId;

  const QuizDeleted({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class QuizzesLoaded extends QuizState {
  final List<QuizModel> quizzes;

  const QuizzesLoaded({required this.quizzes});

  @override
  List<Object?> get props => [quizzes];
}

// ==================== QUIZ TAKING STATES ====================

class QuizStarted extends QuizState {
  final QuizModel quiz;
  final QuizAttempt attempt;
  final QuizAttempt? previousAttempt; // Previous attempt for retakes

  const QuizStarted({
    required this.quiz,
    required this.attempt,
    this.previousAttempt,
  });

  @override
  List<Object?> get props => [quiz, attempt, previousAttempt];
}

class QuizInProgress extends QuizState {
  final QuizModel quiz;
  final QuizAttempt attempt;
  final int currentQuestionIndex;
  final int remainingTime;

  const QuizInProgress({
    required this.quiz,
    required this.attempt,
    required this.currentQuestionIndex,
    required this.remainingTime,
  });

  @override
  List<Object?> get props => [quiz, attempt, currentQuestionIndex, remainingTime];
}

class QuizCompleted extends QuizState {
  final QuizAttempt attempt;
  final QuizModel quiz;

  const QuizCompleted({
    required this.attempt,
    required this.quiz,
  });

  @override
  List<Object?> get props => [attempt, quiz];
}

class QuizAbandoned extends QuizState {
  final String attemptId;

  const QuizAbandoned({required this.attemptId});

  @override
  List<Object?> get props => [attemptId];
}

// ==================== QUIZ RESULTS STATES ====================

class QuizAttemptsLoaded extends QuizState {
  final List<QuizAttempt> attempts;

  const QuizAttemptsLoaded({required this.attempts});

  @override
  List<Object?> get props => [attempts];
}

class QuizResultsLoaded extends QuizState {
  final List<QuizResultSummary> results;

  const QuizResultsLoaded({required this.results});

  @override
  List<Object?> get props => [results];
}

class QuizResultSummaryLoaded extends QuizState {
  final QuizResultSummary result;

  const QuizResultSummaryLoaded({required this.result});

  @override
  List<Object?> get props => [result];
}

// ==================== ERROR STATE ====================

class QuizError extends QuizState {
  final String error;

  const QuizError({required this.error});

  @override
  List<Object?> get props => [error];
}
