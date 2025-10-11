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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect 
              ? Colors.green
              : isAnswered 
                  ? Colors.red
                  : Colors.grey,
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
              color: isCorrect 
                  ? Colors.green.withOpacity(0.1)
                  : isAnswered 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? Colors.green
                        : isAnswered 
                            ? Colors.red
                            : Colors.grey,
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
                  isCorrect 
                      ? Icons.check_circle
                      : isAnswered 
                          ? Icons.cancel
                          : Icons.help_outline,
                  color: isCorrect 
                      ? Colors.green
                      : isAnswered 
                          ? Colors.red
                          : Colors.grey,
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
