import 'package:equatable/equatable.dart';

class QuizState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> quizzes;
  final Map<String, dynamic>? currentQuiz;

  const QuizState({
    this.isLoading = false,
    this.errorMessage,
    this.quizzes = const [],
    this.currentQuiz,
  });

  QuizState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? quizzes,
    Map<String, dynamic>? currentQuiz,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      quizzes: quizzes ?? this.quizzes,
      currentQuiz: currentQuiz ?? this.currentQuiz,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, quizzes, currentQuiz];
}

// Quiz Events
class QuizCreated extends QuizState {
  final Map<String, dynamic> quiz;

  const QuizCreated({required this.quiz});

  @override
  List<Object?> get props => [quiz];
}

class QuizUpdated extends QuizState {
  final Map<String, dynamic> quiz;

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
  final List<Map<String, dynamic>> quizzes;

  const QuizzesLoaded({required this.quizzes});

  @override
  List<Object?> get props => [quizzes];
}

class QuizError extends QuizState {
  final String error;

  const QuizError({required this.error});

  @override
  List<Object?> get props => [error];
}
