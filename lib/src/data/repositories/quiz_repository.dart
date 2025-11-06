import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuizRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
        _auth = auth;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Generate unique ID
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = List.generate(8, (index) => chars[Random().nextInt(chars.length)]).join();
    return '${timestamp}_$randomPart';
  }

  // ==================== QUIZ MANAGEMENT ====================

  /// Get all quizzes for a course
  Future<List<QuizModel>> getCourseQuizzes(String courseId) async {
    try {
      print('QuizRepository: Fetching quizzes for course: $courseId');
      
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .orderBy('order')
          .get();

      final quizzes = <QuizModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          print('QuizRepository: Processing quiz document ${doc.id}: $data');
          final quiz = QuizModel.fromMap(data);
          quizzes.add(quiz);
        } catch (e) {
          print('QuizRepository: Error processing quiz document ${doc.id}: $e');
          print('QuizRepository: Document data: ${doc.data()}');
          // Skip this quiz but continue with others
          continue;
        }
      }

      print('QuizRepository: Found ${quizzes.length} quizzes for course: $courseId');
      return quizzes;
    } catch (e) {
      print('QuizRepository: Error fetching course quizzes: $e');
      throw Exception('Failed to fetch course quizzes: $e');
    }
  }

  /// Get a specific quiz by ID
  Future<QuizModel?> getQuizById(String courseId, String quizId) async {
    try {
      print('QuizRepository: Fetching quiz: $quizId from course: $courseId');
      
      final doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (!doc.exists) {
        print('QuizRepository: Quiz not found: $quizId');
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      print('QuizRepository: Processing quiz document ${doc.id}: $data');
      final quiz = QuizModel.fromMap(data);
      
      print('QuizRepository: Successfully fetched quiz: ${quiz.title}');
      return quiz;
    } catch (e) {
      print('QuizRepository: Error fetching quiz: $e');
      throw Exception('Failed to fetch quiz: $e');
    }
  }

  /// Create a new quiz
  Future<QuizModel> createQuiz(String courseId, QuizModel quiz) async {
    try {
      print('QuizRepository: Creating quiz: ${quiz.title} for course: $courseId');
      
      final quizId = _generateId();
      final quizData = quiz.toMap();
      quizData['id'] = quizId;
      quizData['courseId'] = courseId;
      quizData['createdAt'] = FieldValue.serverTimestamp();
      quizData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .set(quizData);

      // Return the quiz with the new ID and timestamps
      final createdQuiz = QuizModel(
        id: quizId,
        courseId: courseId,
        title: quiz.title,
        description: quiz.description,
        questions: quiz.questions,
        totalMarks: quiz.totalMarks,
        isPremium: quiz.isPremium,
        order: quiz.order,
        createdAt: DateTime.now(), // Use current time instead of FieldValue
        updatedAt: DateTime.now(), // Use current time instead of FieldValue
        timeLimitMinutes: quiz.timeLimitMinutes,
        passingScore: quiz.passingScore,
        allowRetake: quiz.allowRetake,
        maxAttempts: quiz.maxAttempts,
      );
      
      print('QuizRepository: Successfully created quiz: ${createdQuiz.title}');
      return createdQuiz;
    } catch (e) {
      print('QuizRepository: Error creating quiz: $e');
      throw Exception('Failed to create quiz: $e');
    }
  }

  /// Update a quiz
  Future<QuizModel> updateQuiz(String courseId, String quizId, QuizModel quiz) async {
    try {
      print('QuizRepository: Updating quiz: $quizId for course: $courseId');
      
      final quizData = quiz.toMap();
      quizData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .update(quizData);

      // Return the quiz with updated timestamp
      final updatedQuiz = QuizModel(
        id: quizId,
        courseId: courseId,
        title: quiz.title,
        description: quiz.description,
        questions: quiz.questions,
        totalMarks: quiz.totalMarks,
        isPremium: quiz.isPremium,
        order: quiz.order,
        createdAt: quiz.createdAt,
        updatedAt: DateTime.now(), // Use current time instead of FieldValue
        timeLimitMinutes: quiz.timeLimitMinutes,
        passingScore: quiz.passingScore,
        allowRetake: quiz.allowRetake,
        maxAttempts: quiz.maxAttempts,
      );
      
      print('QuizRepository: Successfully updated quiz: ${updatedQuiz.title}');
      return updatedQuiz;
    } catch (e) {
      print('QuizRepository: Error updating quiz: $e');
      throw Exception('Failed to update quiz: $e');
    }
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String courseId, String quizId) async {
    try {
      print('QuizRepository: Deleting quiz: $quizId from course: $courseId');
      
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      // Also delete all quiz attempts for this quiz
      await _deleteQuizAttempts(quizId);
      
      print('QuizRepository: Successfully deleted quiz: $quizId');
    } catch (e) {
      print('QuizRepository: Error deleting quiz: $e');
      throw Exception('Failed to delete quiz: $e');
    }
  }

  // ==================== QUIZ ATTEMPTS ====================

  /// Start a new quiz attempt
  Future<QuizAttempt> startQuizAttempt(String courseId, String quizId, QuizModel quiz) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('QuizRepository: Starting quiz attempt for quiz: $quizId, user: $userId');

      // Get next attempt number
      int attemptNumber;
      try {
        attemptNumber = await _getNextAttemptNumber(userId, quizId);
      } catch (e) {
        print('QuizRepository: Error getting attempt number, defaulting to 1: $e');
        attemptNumber = 1; // Default to first attempt if there's an error
      }

      // Check if user can retake
      if (attemptNumber > quiz.maxAttempts && !quiz.allowRetake) {
        throw Exception('Maximum attempts reached for this quiz');
      }

      final attemptId = _generateId();
      final attempt = QuizAttempt(
        id: attemptId,
        quizId: quizId,
        courseId: courseId,
        userId: userId,
        answers: [],
        totalMarks: quiz.totalMarks,
        marksObtained: 0,
        percentage: 0.0,
        isPassed: false,
        startedAt: DateTime.now(),
        attemptNumber: attemptNumber,
        timeSpentPerQuestion: {},
      );

      await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .set(attempt.toMap());

      print('QuizRepository: Successfully started quiz attempt: $attemptId');
      return attempt;
    } catch (e) {
      print('QuizRepository: Error starting quiz attempt: $e');
      throw Exception('Failed to start quiz attempt: $e');
    }
  }

  /// Save quiz attempt answer
  Future<void> saveQuizAnswer(String attemptId, QuizAttemptAnswer answer) async {
    try {
      print('QuizRepository: Saving answer for attempt: $attemptId, question: ${answer.questionId}');

      // Validate questionId for Firestore field path
      final questionId = answer.questionId.trim();
      if (questionId.isEmpty) {
        throw Exception('Invalid question ID for saving answer');
      }

      // Get current attempt to update answers array properly
      final attemptDoc = await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .get();
      
      if (!attemptDoc.exists) {
        throw Exception('Quiz attempt not found');
      }
      
      final attemptData = attemptDoc.data()!;
      final currentAnswers = (attemptData['answers'] as List<dynamic>?)
          ?.map((a) => QuizAttemptAnswer.fromMap(a as Map<String, dynamic>))
          .toList() ?? [];
      
      // Check if answer already exists for this question
      final existingAnswerIndex = currentAnswers.indexWhere(
        (existingAnswer) => existingAnswer.questionId == answer.questionId
      );
      
      if (existingAnswerIndex >= 0) {
        // Update existing answer
        currentAnswers[existingAnswerIndex] = answer;
        print('QuizRepository: Updated existing answer for question: ${answer.questionId}');
      } else {
        // Add new answer
        currentAnswers.add(answer);
        print('QuizRepository: Added new answer for question: ${answer.questionId}');
      }
      
      // Update the document with the modified answers array
      await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .update({
        'answers': currentAnswers.map((a) => a.toMap()).toList(),
        'timeSpentPerQuestion.$questionId': answer.timeSpentSeconds ?? 0,
      });

      print('QuizRepository: Successfully saved answer for question: ${answer.questionId}');
    } catch (e) {
      print('QuizRepository: Error saving quiz answer: $e');
      throw Exception('Failed to save quiz answer: $e');
    }
  }

  /// Complete quiz attempt
  Future<QuizAttempt> completeQuizAttempt(String attemptId, List<QuizAttemptAnswer> answers) async {
    try {
      print('QuizRepository: Completing quiz attempt: $attemptId');
      print('QuizRepository: Processing ${answers.length} answers');

      // Get the quiz to calculate correct total marks
      final attemptDoc = await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .get();
      
      if (!attemptDoc.exists) {
        throw Exception('Quiz attempt not found');
      }
      
      final attemptData = attemptDoc.data()!;
      final quizId = attemptData['quizId'] as String;
      final courseId = attemptData['courseId'] as String;
      
      // Get quiz details to calculate correct total marks
      final quiz = await getQuizById(courseId, quizId);
      if (quiz == null) {
        throw Exception('Quiz not found for completion');
      }
      
      // Calculate correct total possible marks from quiz questions
      final totalPossibleMarks = quiz.questions.fold<int>(0, (sum, question) => sum + question.marks);
      final totalMarksObtained = answers.fold<int>(0, (sum, answer) => sum + answer.marksObtained);
      final percentage = totalPossibleMarks > 0 ? (totalMarksObtained / totalPossibleMarks) * 100 : 0.0;

      final completedAt = DateTime.now();
      final isPassed = percentage >= quiz.passingScore; // Use quiz-specific passing score
      
      print('QuizRepository: Total possible marks: $totalPossibleMarks');
      print('QuizRepository: Marks obtained: $totalMarksObtained');
      print('QuizRepository: Percentage: ${percentage.toStringAsFixed(1)}%');
      print('QuizRepository: Passing score: ${quiz.passingScore}%');
      print('QuizRepository: Is passed: $isPassed');

      final updateData = {
        'answers': answers.map((a) => a.toMap()).toList(),
        'marksObtained': totalMarksObtained,
        'percentage': percentage,
        'isPassed': isPassed,
        'completedAt': Timestamp.fromDate(completedAt),
        'isAbandoned': false,
      };

      await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .update(updateData);

      // Get the updated attempt
      final doc = await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .get();

      if (!doc.exists) {
        throw Exception('Quiz attempt not found after completion');
      }

      final completedAttempt = QuizAttempt.fromMap(doc.data()!);
      
      // Update user progress
      await _updateUserQuizProgress(completedAttempt);

      print('QuizRepository: Successfully completed quiz attempt: $attemptId');
      print('QuizRepository: Final score: $totalMarksObtained/$totalPossibleMarks (${percentage.toStringAsFixed(1)}%)');
      
      return completedAttempt;
    } catch (e) {
      print('QuizRepository: Error completing quiz attempt: $e');
      throw Exception('Failed to complete quiz attempt: $e');
    }
  }

  /// Abandon quiz attempt
  Future<void> abandonQuizAttempt(String attemptId) async {
    try {
      print('QuizRepository: Abandoning quiz attempt: $attemptId');

      // Delete the quiz attempt document instead of just marking it as abandoned
      await _firestore
          .collection('quiz_attempts')
          .doc(attemptId)
          .delete();

      print('QuizRepository: Successfully deleted abandoned quiz attempt: $attemptId');
    } catch (e) {
      print('QuizRepository: Error abandoning quiz attempt: $e');
      throw Exception('Failed to abandon quiz attempt: $e');
    }
  }

  // ==================== QUIZ RESULTS ====================

  /// Get user's quiz attempts for a specific quiz
  Future<List<QuizAttempt>> getUserQuizAttempts(String quizId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('QuizRepository: Fetching quiz attempts for quiz: $quizId, user: $userId');

      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('userId', isEqualTo: userId)
          .where('quizId', isEqualTo: quizId)
          .get();

      final attempts = snapshot.docs
          .map((doc) => QuizAttempt.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt)); // Client-side sorting

      print('QuizRepository: Found ${attempts.length} attempts for quiz: $quizId');
      return attempts;
    } catch (e) {
      print('QuizRepository: Error fetching quiz attempts: $e');
      throw Exception('Failed to fetch quiz attempts: $e');
    }
  }

  /// Get user's quiz result summary
  Future<QuizResultSummary?> getUserQuizResultSummary(String quizId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('QuizRepository: Fetching quiz result summary for quiz: $quizId, user: $userId');

      final attempts = await getUserQuizAttempts(quizId);
      
      if (attempts.isEmpty) {
        print('QuizRepository: No attempts found for quiz: $quizId');
        return null;
      }

      // Find best attempt
      QuizAttempt? bestAttempt;
      double bestPercentage = 0.0;

      print('QuizRepository: Analyzing ${attempts.length} attempts to find best:');
      for (int i = 0; i < attempts.length; i++) {
        final attempt = attempts[i];
        print('QuizRepository: Attempt ${i + 1}: ${attempt.marksObtained}/${attempt.totalMarks} = ${attempt.percentage}% (Abandoned: ${attempt.isAbandoned})');

        if (!attempt.isAbandoned && attempt.percentage > bestPercentage) {
          bestAttempt = attempt;
          bestPercentage = attempt.percentage;
          print('QuizRepository: New best found - Attempt ${attempt.attemptNumber} with ${bestPercentage}%');
        }
      }

      if (bestAttempt == null) {
        print('QuizRepository: No valid non-abandoned attempts, using first attempt');
        bestAttempt = attempts.first;
        bestPercentage = bestAttempt.percentage;
      }

      // Get quiz details to determine retake eligibility
      final courseId = bestAttempt.courseId;
      final quiz = await getQuizById(courseId, quizId);
      final canRetake = quiz?.allowRetake ?? true;
      final maxAttempts = quiz?.maxAttempts ?? 3;
      final remainingAttempts = max(0, maxAttempts - attempts.length);

      final summary = QuizResultSummary(
        quizId: quizId,
        courseId: courseId,
        userId: userId,
        totalAttempts: attempts.length,
        bestAttempt: bestAttempt.attemptNumber,
        bestMarks: bestAttempt.marksObtained,
        bestPercentage: bestPercentage,
        hasPassed: bestAttempt.isPassed,
        lastAttemptAt: attempts.first.startedAt,
        canRetake: canRetake && remainingAttempts > 0,
        remainingAttempts: remainingAttempts,
      );

      print('QuizRepository: Generated quiz result summary for quiz: $quizId');
      print('QuizRepository: Best score: ${bestAttempt.marksObtained}/${bestAttempt.totalMarks} (${bestPercentage.toStringAsFixed(1)}%)');
      
      return summary;
    } catch (e) {
      print('QuizRepository: Error fetching quiz result summary: $e');
      throw Exception('Failed to fetch quiz result summary: $e');
    }
  }

  /// Get all quiz results for a course
  Future<List<QuizResultSummary>> getCourseQuizResults(String courseId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('QuizRepository: Fetching quiz results for course: $courseId, user: $userId');

      // Get all quizzes for the course
      final quizzes = await getCourseQuizzes(courseId);
      
      // Get result summary for each quiz
      final results = <QuizResultSummary>[];
      for (final quiz in quizzes) {
        final summary = await getUserQuizResultSummary(quiz.id);
        if (summary != null) {
          results.add(summary);
        }
      }

      print('QuizRepository: Found ${results.length} quiz results for course: $courseId');
      return results;
    } catch (e) {
      print('QuizRepository: Error fetching course quiz results: $e');
      throw Exception('Failed to fetch course quiz results: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get next attempt number for a user and quiz
  Future<int> _getNextAttemptNumber(String userId, String quizId) async {
    final attempts = await getUserQuizAttempts(quizId);
    return attempts.length + 1;
  }

  /// Delete all quiz attempts for a quiz (when quiz is deleted)
  Future<void> _deleteQuizAttempts(String quizId) async {
    try {
      print('QuizRepository: Deleting all attempts for quiz: $quizId');
      
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('quiz_attempts')
          .where('quizId', isEqualTo: quizId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('QuizRepository: Successfully deleted ${snapshot.docs.length} attempts for quiz: $quizId');
    } catch (e) {
      print('QuizRepository: Error deleting quiz attempts: $e');
      // Don't throw error as this is a cleanup operation
    }
  }

  /// Update user progress with quiz completion
  Future<void> _updateUserQuizProgress(QuizAttempt attempt) async {
    try {
      print('QuizRepository: Updating user progress for quiz: ${attempt.quizId}');
      
      // This would integrate with UserProgressRepository
      // For now, we'll just log the completion
      print('QuizRepository: Quiz ${attempt.quizId} completed with ${attempt.percentage.toStringAsFixed(1)}%');
      
      // TODO: Integrate with UserProgressRepository to update course completion
      // This should be called when a user completes a quiz to update their overall course progress
      
    } catch (e) {
      print('QuizRepository: Error updating user quiz progress: $e');
      // Don't throw error as this is supplementary functionality
    }
  }
}
