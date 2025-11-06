import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';

class QuizResultDetailsWidget extends StatelessWidget {
  final QuizModel quiz;
  final QuizAttempt attempt;
  final bool isDark;

  const QuizResultDetailsWidget({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.isDark,
  });

  bool get _canShowAnswers {
    // Check if answers should be shown based on quiz settings
    final showAnswers = quiz.showAnswersAfterCompletion ?? true;
    if (!showAnswers) {
      return false;
    }
    // Check if current attempt number meets the threshold
    final requiredAttempts = quiz.showAnswersAfterAttempts ?? 1;
    return attempt.attemptNumber >= requiredAttempts;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Review',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Show message if answers are not available
          if (!_canShowAnswers) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_clock,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Answers Not Available Yet',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (quiz.showAnswersAfterCompletion ?? true)
                        ? 'Complete ${quiz.showAnswersAfterAttempts ?? 1} ${(quiz.showAnswersAfterAttempts ?? 1) == 1 ? "attempt" : "attempts"} to view correct answers.\nCurrent attempt: ${attempt.attemptNumber}'
                        : 'The instructor has disabled answer viewing for this quiz.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          ...quiz.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = attempt.answers.firstWhere(
              (a) => a.questionId == question.id,
              orElse: () => QuizAttemptAnswer(
                questionId: question.id,
                selectedAnswerIndex: -1,
                isCorrect: false,
                marksObtained: 0,
                answeredAt: DateTime.now(),
              ),
            );

            return _buildQuestionReviewCard(
              question,
              userAnswer,
              index + 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(
    QuizQuestion question,
    QuizAttemptAnswer userAnswer,
    int questionNumber,
  ) {
    final isAnswered = userAnswer.selectedAnswerIndex >= 0;
    final isCorrect = userAnswer.isCorrect;

    // Determine colors based on whether answers can be shown
    Color borderColor;
    Color backgroundColor;
    Color badgeColor;
    IconData headerIcon;

    if (_canShowAnswers) {
      // Show correct/incorrect status
      borderColor = isCorrect ? Colors.green : (isAnswered ? Colors.red : Colors.grey);
      backgroundColor = isCorrect ? Colors.green.withOpacity(0.1) : (isAnswered ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1));
      badgeColor = isCorrect ? Colors.green : (isAnswered ? Colors.red : Colors.grey);
      headerIcon = isCorrect ? Icons.check_circle : (isAnswered ? Icons.cancel : Icons.help_outline);
    } else {
      // Only show if answered or not
      borderColor = isAnswered ? Colors.blue : Colors.grey;
      backgroundColor = isAnswered ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1);
      badgeColor = isAnswered ? Colors.blue : Colors.grey;
      headerIcon = isAnswered ? Icons.check_circle_outline : Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question $questionNumber',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${question.marks} mark${question.marks > 1 ? 's' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  headerIcon,
                  color: badgeColor,
                  size: 24,
                ),
              ],
            ),
          ),
          
          // Question Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Text
                Text(
                  question.questionText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Answer Options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isUserAnswer = userAnswer.selectedAnswerIndex == index;
                  final isCorrectAnswer = index == question.correctAnswerIndex;

                  Color? backgroundColor;
                  Color? borderColor;
                  IconData? icon;

                  // If answers can be shown, display correct/incorrect indicators
                  if (_canShowAnswers) {
                    if (isCorrectAnswer) {
                      backgroundColor = Colors.green.withOpacity(0.1);
                      borderColor = Colors.green;
                      icon = Icons.check_circle;
                    } else if (isUserAnswer && !isCorrectAnswer) {
                      backgroundColor = Colors.red.withOpacity(0.1);
                      borderColor = Colors.red;
                      icon = Icons.cancel;
                    } else {
                      backgroundColor = isDark ? Colors.grey[800] : Colors.grey[100];
                      borderColor = Colors.grey;
                    }
                  } else {
                    // If answers cannot be shown, only highlight user's answer
                    if (isUserAnswer) {
                      backgroundColor = Colors.blue.withOpacity(0.1);
                      borderColor = Colors.blue;
                      icon = Icons.check_circle_outline;
                    } else {
                      backgroundColor = isDark ? Colors.grey[800] : Colors.grey[100];
                      borderColor = Colors.grey;
                    }
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        
                        if (icon != null)
                          Icon(
                            icon,
                            color: borderColor,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                }).toList(),
                
                // Explanation
                if (question.explanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Time Information
                if (userAnswer.timeSpentSeconds != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Time spent: ${userAnswer.timeSpentSeconds}s',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
