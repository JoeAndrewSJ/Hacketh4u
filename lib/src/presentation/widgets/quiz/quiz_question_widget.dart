import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';

class QuizQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedAnswerIndex;
  final Function(int) onAnswerSelected;
  final bool isDark;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswerIndex,
    required this.onAnswerSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${question.marks}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
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
                      '${question.marks} Mark${question.marks > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (question.timeLimitSeconds != null)
                      Text(
                        '${question.timeLimitSeconds}s',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Question Text
          Builder(
            builder: (context) {
              // Debug: Print the actual question data
              print('QuizQuestionWidget: Displaying question: ${question.questionText}');
              print('QuizQuestionWidget: Question type: ${question.questionText.runtimeType}');
              
              // Handle case where questionText might be a Map or other object
              String displayText;
              if (question.questionText is Map) {
                displayText = question.questionText.toString();
              } else {
                displayText = question.questionText?.toString() ?? 'No question text available';
              }
              
              return Text(
                displayText,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Answer Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswerIndex == index;
            
            // Debug: Print option data
            print('QuizQuestionWidget: Question ID: ${question.id}');
            print('QuizQuestionWidget: Selected answer index: $selectedAnswerIndex');
            print('QuizQuestionWidget: Option $index: $option (type: ${option.runtimeType})');
            print('QuizQuestionWidget: Is selected: $isSelected');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onAnswerSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryLight.withOpacity(0.1)
                        : isDark ? AppTheme.backgroundDark : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryLight
                          : isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryLight
                              : isDark ? Colors.grey[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Option Text
                      Expanded(
                        child: Text(
                          option?.toString() ?? 'No option text',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      // Selection Indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryLight,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          // Question Explanation (if available and answered)
          if (question.explanation != null && selectedAnswerIndex != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedAnswerIndex == question.correctAnswerIndex
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedAnswerIndex == question.correctAnswerIndex
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selectedAnswerIndex == question.correctAnswerIndex
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: selectedAnswerIndex == question.correctAnswerIndex
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedAnswerIndex == question.correctAnswerIndex
                            ? 'Correct Answer!'
                            : 'Incorrect Answer',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selectedAnswerIndex == question.correctAnswerIndex
                              ? Colors.green
                              : Colors.red,
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
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
