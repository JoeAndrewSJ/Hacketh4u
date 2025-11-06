import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Quiz Question Model
class QuizQuestion extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final int marks;
  final int? timeLimitSeconds;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.marks = 1,
    this.timeLimitSeconds,
  });

  // Helper method for safe string conversion
  static String _safeStringConversion(dynamic value) {
    print('_safeStringConversion: Input value: $value (type: ${value.runtimeType})');
    
    if (value == null) {
      print('_safeStringConversion: Value is null, returning empty string');
      return '';
    }
    if (value is String) {
      print('_safeStringConversion: Value is String: "$value"');
      return value;
    }
    if (value is Map) {
      print('_safeStringConversion: Value is Map: $value');
      // If it's a Map, try to extract a meaningful string
      if (value.containsKey('text')) {
        final result = value['text']?.toString() ?? '';
        print('_safeStringConversion: Extracted text from Map: "$result"');
        return result;
      }
      final result = value.toString();
      print('_safeStringConversion: Converted Map to String: "$result"');
      return result;
    }
    final result = value.toString();
    print('_safeStringConversion: Converted to String: "$result"');
    return result;
  }

  // Helper method for safe list conversion
  static List<String> _safeListConversion(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is String) return e;
        if (e is Map && e.containsKey('text')) {
          return e['text']?.toString() ?? '';
        }
        return e.toString();
      }).toList();
    }
    return [];
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    // Debug print to see the data structure
    print('QuizQuestion.fromMap: Processing question data: $data');
    
    final id = data['id']?.toString() ?? '';
    final questionText = _safeStringConversion(data['questionText']);
    final options = _safeListConversion(data['options']);
    
    // Debug: Print the extracted values
    print('QuizQuestion.fromMap: Extracted ID: "$id"');
    print('QuizQuestion.fromMap: Extracted questionText: "$questionText"');
    print('QuizQuestion.fromMap: Extracted options: $options');
    
    return QuizQuestion(
      id: id,
      questionText: questionText,
      options: options,
      correctAnswerIndex: (data['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      explanation: data['explanation']?.toString(),
      marks: (data['marks'] as num?)?.toInt() ?? 1,
      timeLimitSeconds: (data['timeLimitSeconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'marks': marks,
      'timeLimitSeconds': timeLimitSeconds,
    };
  }

  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswerIndex,
        explanation,
        marks,
        timeLimitSeconds,
      ];
}

/// Quiz Model
class QuizModel extends Equatable {
  final String id;
  final String courseId;
  final String? moduleId;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final int totalMarks;
  final bool isPremium;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? timeLimitMinutes;
  final int passingScore;
  final bool allowRetake;
  final int maxAttempts;
  final bool? showAnswersAfterCompletion;
  final int? showAnswersAfterAttempts;

  const QuizModel({
    required this.id,
    required this.courseId,
    this.moduleId,
    required this.title,
    required this.description,
    required this.questions,
    required this.totalMarks,
    this.isPremium = false,
    this.order = 1,
    this.createdAt,
    this.updatedAt,
    this.timeLimitMinutes,
    this.passingScore = 60,
    this.allowRetake = true,
    this.maxAttempts = 3,
    this.showAnswersAfterCompletion = true,
    this.showAnswersAfterAttempts = 1,
  });

  // Helper method for safe timestamp conversion
  static DateTime? _safeTimestampConversion(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is FieldValue) {
      // FieldValue.serverTimestamp() means the timestamp will be set by Firestore
      // Return null for now, it will be properly set when read from Firestore
      return null;
    }
    if (value is DateTime) return value;
    return null;
  }

  factory QuizModel.fromMap(Map<String, dynamic> data) {
    // Debug print to see the data structure
    print('QuizModel.fromMap: Processing quiz data: $data');
    
    try {
      return QuizModel(
        id: data['id']?.toString() ?? '',
        courseId: data['courseId']?.toString() ?? '',
        moduleId: data['moduleId']?.toString(),
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        questions: (data['questions'] as List<dynamic>?)
                ?.map((q) {
                  print('QuizModel.fromMap: Processing question: $q');
                  return QuizQuestion.fromMap(q as Map<String, dynamic>);
                })
                .toList() ??
            [],
        totalMarks: (data['totalMarks'] as num?)?.toInt() ?? 0,
        isPremium: data['isPremium'] as bool? ?? false,
        order: (data['order'] as num?)?.toInt() ?? 1,
        createdAt: _safeTimestampConversion(data['createdAt']),
        updatedAt: _safeTimestampConversion(data['updatedAt']),
        timeLimitMinutes: (data['timeLimitMinutes'] as num?)?.toInt(),
        passingScore: (data['passingScore'] as num?)?.toInt() ?? 60,
        allowRetake: data['allowRetake'] as bool? ?? true,
        maxAttempts: (data['maxAttempts'] as num?)?.toInt() ?? 3,
        showAnswersAfterCompletion: data['showAnswersAfterCompletion'] as bool? ?? true,
        showAnswersAfterAttempts: (data['showAnswersAfterAttempts'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      print('QuizModel.fromMap: Error processing quiz data: $e');
      print('QuizModel.fromMap: Problematic data: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalMarks': totalMarks,
      'isPremium': isPremium,
      'order': order,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'timeLimitMinutes': timeLimitMinutes,
      'passingScore': passingScore,
      'allowRetake': allowRetake,
      'maxAttempts': maxAttempts,
      'showAnswersAfterCompletion': showAnswersAfterCompletion ?? true,
      'showAnswersAfterAttempts': showAnswersAfterAttempts ?? 1,
    };
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        moduleId,
        title,
        description,
        questions,
        totalMarks,
        isPremium,
        order,
        createdAt,
        updatedAt,
        timeLimitMinutes,
        passingScore,
        allowRetake,
        maxAttempts,
        showAnswersAfterCompletion,
        showAnswersAfterAttempts,
      ];
}

/// Quiz Attempt Answer Model
class QuizAttemptAnswer extends Equatable {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final int marksObtained;
  final DateTime answeredAt;
  final int? timeSpentSeconds;

  const QuizAttemptAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.marksObtained,
    required this.answeredAt,
    this.timeSpentSeconds,
  });

  factory QuizAttemptAnswer.fromMap(Map<String, dynamic> data) {
    return QuizAttemptAnswer(
      questionId: data['questionId'] ?? '',
      selectedAnswerIndex: data['selectedAnswerIndex'] ?? -1,
      isCorrect: data['isCorrect'] ?? false,
      marksObtained: data['marksObtained'] ?? 0,
      answeredAt: (data['answeredAt'] as Timestamp).toDate(),
      timeSpentSeconds: data['timeSpentSeconds'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'marksObtained': marksObtained,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  @override
  List<Object?> get props => [
        questionId,
        selectedAnswerIndex,
        isCorrect,
        marksObtained,
        answeredAt,
        timeSpentSeconds,
      ];
}

/// Quiz Attempt Model
class QuizAttempt extends Equatable {
  final String id;
  final String quizId;
  final String courseId;
  final String userId;
  final List<QuizAttemptAnswer> answers;
  final int totalMarks;
  final int marksObtained;
  final double percentage;
  final bool isPassed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int attemptNumber;
  final Map<String, int> timeSpentPerQuestion;
  final bool isAbandoned;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.courseId,
    required this.userId,
    required this.answers,
    required this.totalMarks,
    required this.marksObtained,
    required this.percentage,
    required this.isPassed,
    required this.startedAt,
    this.completedAt,
    required this.attemptNumber,
    required this.timeSpentPerQuestion,
    this.isAbandoned = false,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> data) {
    return QuizAttempt(
      id: data['id'] ?? '',
      quizId: data['quizId'] ?? '',
      courseId: data['courseId'] ?? '',
      userId: data['userId'] ?? '',
      answers: (data['answers'] as List<dynamic>?)
              ?.map((a) => QuizAttemptAnswer.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      totalMarks: data['totalMarks'] ?? 0,
      marksObtained: data['marksObtained'] ?? 0,
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      isPassed: data['isPassed'] ?? false,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      attemptNumber: data['attemptNumber'] ?? 1,
      timeSpentPerQuestion: Map<String, int>.from(data['timeSpentPerQuestion'] ?? {}),
      isAbandoned: data['isAbandoned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'courseId': courseId,
      'userId': userId,
      'answers': answers.map((a) => a.toMap()).toList(),
      'totalMarks': totalMarks,
      'marksObtained': marksObtained,
      'percentage': percentage,
      'isPassed': isPassed,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'attemptNumber': attemptNumber,
      'timeSpentPerQuestion': timeSpentPerQuestion,
      'isAbandoned': isAbandoned,
    };
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        courseId,
        userId,
        answers,
        totalMarks,
        marksObtained,
        percentage,
        isPassed,
        startedAt,
        completedAt,
        attemptNumber,
        timeSpentPerQuestion,
        isAbandoned,
      ];
}

/// Quiz Result Summary Model
class QuizResultSummary extends Equatable {
  final String quizId;
  final String courseId;
  final String userId;
  final int totalAttempts;
  final int bestAttempt;
  final int bestMarks;
  final double bestPercentage;
  final bool hasPassed;
  final DateTime? lastAttemptAt;
  final bool canRetake;
  final int remainingAttempts;

  const QuizResultSummary({
    required this.quizId,
    required this.courseId,
    required this.userId,
    required this.totalAttempts,
    required this.bestAttempt,
    required this.bestMarks,
    required this.bestPercentage,
    required this.hasPassed,
    this.lastAttemptAt,
    required this.canRetake,
    required this.remainingAttempts,
  });

  factory QuizResultSummary.fromMap(Map<String, dynamic> data) {
    return QuizResultSummary(
      quizId: data['quizId'] ?? '',
      courseId: data['courseId'] ?? '',
      userId: data['userId'] ?? '',
      totalAttempts: data['totalAttempts'] ?? 0,
      bestAttempt: data['bestAttempt'] ?? 0,
      bestMarks: data['bestMarks'] ?? 0,
      bestPercentage: (data['bestPercentage'] ?? 0.0).toDouble(),
      hasPassed: data['hasPassed'] ?? false,
      lastAttemptAt: (data['lastAttemptAt'] as Timestamp?)?.toDate(),
      canRetake: data['canRetake'] ?? true,
      remainingAttempts: data['remainingAttempts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'courseId': courseId,
      'userId': userId,
      'totalAttempts': totalAttempts,
      'bestAttempt': bestAttempt,
      'bestMarks': bestMarks,
      'bestPercentage': bestPercentage,
      'hasPassed': hasPassed,
      'lastAttemptAt': lastAttemptAt != null ? Timestamp.fromDate(lastAttemptAt!) : null,
      'canRetake': canRetake,
      'remainingAttempts': remainingAttempts,
    };
  }

  @override
  List<Object?> get props => [
        quizId,
        courseId,
        userId,
        totalAttempts,
        bestAttempt,
        bestMarks,
        bestPercentage,
        hasPassed,
        lastAttemptAt,
        canRetake,
        remainingAttempts,
      ];
}
