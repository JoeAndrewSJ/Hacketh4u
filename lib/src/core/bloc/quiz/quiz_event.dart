import 'package:equatable/equatable.dart';
import '../../../data/models/quiz_model.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

// ==================== QUIZ MANAGEMENT EVENTS ====================

class CreateQuiz extends QuizEvent {
  final String courseId;
  final QuizModel quiz;

  const CreateQuiz({
    required this.courseId,
    required this.quiz,
  });

  @override
  List<Object?> get props => [courseId, quiz];
}

class UpdateQuiz extends QuizEvent {
  final String courseId;
  final String quizId;
  final QuizModel quiz;

  const UpdateQuiz({
    required this.courseId,
    required this.quizId,
    required this.quiz,
  });

  @override
  List<Object?> get props => [courseId, quizId, quiz];
}

class DeleteQuiz extends QuizEvent {
  final String courseId;
  final String quizId;

  const DeleteQuiz({
    required this.courseId,
    required this.quizId,
  });

  @override
  List<Object?> get props => [courseId, quizId];
}

class LoadCourseQuizzes extends QuizEvent {
  final String courseId;

  const LoadCourseQuizzes({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class ReorderQuizzes extends QuizEvent {
  final String courseId;
  final List<QuizModel> reorderedQuizzes;

  const ReorderQuizzes({
    required this.courseId,
    required this.reorderedQuizzes,
  });

  @override
  List<Object?> get props => [courseId, reorderedQuizzes];
}

// ==================== QUIZ TAKING EVENTS ====================

class StartQuiz extends QuizEvent {
  final String courseId;
  final String quizId;

  const StartQuiz({
    required this.courseId,
    required this.quizId,
  });

  @override
  List<Object?> get props => [courseId, quizId];
}

class AnswerQuestion extends QuizEvent {
  final String attemptId;
  final QuizAttemptAnswer answer;

  const AnswerQuestion({
    required this.attemptId,
    required this.answer,
  });

  @override
  List<Object?> get props => [attemptId, answer];
}

class CompleteQuiz extends QuizEvent {
  final String attemptId;

  const CompleteQuiz({required this.attemptId});

  @override
  List<Object?> get props => [attemptId];
}

class AbandonQuiz extends QuizEvent {
  final String attemptId;

  const AbandonQuiz({required this.attemptId});

  @override
  List<Object?> get props => [attemptId];
}

class LoadQuizAttempt extends QuizEvent {
  final String attemptId;

  const LoadQuizAttempt({required this.attemptId});

  @override
  List<Object?> get props => [attemptId];
}

// ==================== QUIZ RESULTS EVENTS ====================

class LoadUserQuizResults extends QuizEvent {
  final String quizId;

  const LoadUserQuizResults({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class LoadCourseQuizResults extends QuizEvent {
  final String courseId;

  const LoadCourseQuizResults({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class LoadQuizAttempts extends QuizEvent {
  final String quizId;

  const LoadQuizAttempts({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

// ==================== QUIZ STATE MANAGEMENT ====================

class ResetQuizState extends QuizEvent {
  const ResetQuizState();

  @override
  List<Object?> get props => [];
}

class UpdateQuizTimer extends QuizEvent {
  final int remainingSeconds;

  const UpdateQuizTimer({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}
