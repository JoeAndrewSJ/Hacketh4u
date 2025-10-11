import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final FirebaseFirestore _firestore;
  final Random _random;

  QuizBloc({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore,
        _random = Random(),
        super(const QuizState()) {
    on<CreateQuiz>(_onCreateQuiz);
    on<UpdateQuiz>(_onUpdateQuiz);
    on<DeleteQuiz>(_onDeleteQuiz);
    on<LoadCourseQuizzes>(_onLoadCourseQuizzes);
    on<ReorderQuizzes>(_onReorderQuizzes);
  }

  Future<void> _onCreateQuiz(CreateQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final quizId = _generateId();
      final quizData = {
        'id': quizId,
        'courseId': event.courseId,
        'title': event.quizData['title'],
        'description': event.quizData['description'],
        'totalMarks': event.quizData['totalMarks'],
        'isPremium': event.quizData['isPremium'] ?? false,
        'questions': event.quizData['questions'],
        'order': event.quizData['order'] ?? 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('courses')
          .doc(event.courseId)
          .collection('quizzes')
          .doc(quizId)
          .set(quizData);

      emit(QuizCreated(quiz: quizData));
    } catch (e) {
      emit(QuizError(error: e.toString()));
    }
  }

  Future<void> _onUpdateQuiz(UpdateQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final updateData = {
        ...event.quizData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('courses')
          .doc(event.courseId)
          .collection('quizzes')
          .doc(event.quizId)
          .update(updateData);

      final updatedQuiz = {
        'id': event.quizId,
        'courseId': event.courseId,
        ...updateData,
      };

      emit(QuizUpdated(quiz: updatedQuiz));
    } catch (e) {
      emit(QuizError(error: e.toString()));
    }
  }

  Future<void> _onDeleteQuiz(DeleteQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      await _firestore
          .collection('courses')
          .doc(event.courseId)
          .collection('quizzes')
          .doc(event.quizId)
          .delete();

      emit(QuizDeleted(quizId: event.quizId));
    } catch (e) {
      emit(QuizError(error: e.toString()));
    }
  }

  Future<void> _onLoadCourseQuizzes(LoadCourseQuizzes event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(event.courseId)
          .collection('quizzes')
          .orderBy('order')
          .get();

      final quizzes = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      emit(QuizzesLoaded(quizzes: quizzes));
    } catch (e) {
      emit(QuizError(error: e.toString()));
    }
  }

  Future<void> _onReorderQuizzes(ReorderQuizzes event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < event.reorderedQuizzes.length; i++) {
        final quiz = event.reorderedQuizzes[i];
        final quizRef = _firestore
            .collection('courses')
            .doc(event.courseId)
            .collection('quizzes')
            .doc(quiz['id']);
        
        batch.update(quizRef, {'order': i + 1});
      }
      
      await batch.commit();
      
      emit(QuizzesLoaded(quizzes: event.reorderedQuizzes));
    } catch (e) {
      emit(QuizError(error: e.toString()));
    }
  }

  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(8, (index) => chars[_random.nextInt(chars.length)]).join();
    return '${timestamp}_$randomPart';
  }
}
