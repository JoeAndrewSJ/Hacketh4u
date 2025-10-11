import 'package:equatable/equatable.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class CreateQuiz extends QuizEvent {
  final String courseId;
  final Map<String, dynamic> quizData;

  const CreateQuiz({
    required this.courseId,
    required this.quizData,
  });

  @override
  List<Object?> get props => [courseId, quizData];
}

class UpdateQuiz extends QuizEvent {
  final String courseId;
  final String quizId;
  final Map<String, dynamic> quizData;

  const UpdateQuiz({
    required this.courseId,
    required this.quizId,
    required this.quizData,
  });

  @override
  List<Object?> get props => [courseId, quizId, quizData];
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
  final List<Map<String, dynamic>> reorderedQuizzes;

  const ReorderQuizzes({
    required this.courseId,
    required this.reorderedQuizzes,
  });

  @override
  List<Object?> get props => [courseId, reorderedQuizzes];
}
