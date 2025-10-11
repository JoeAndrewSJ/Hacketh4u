import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuizProgressWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final bool isDark;

  const QuizProgressWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentQuestion / totalQuestions;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $currentQuestion of $totalQuestions',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Question Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(totalQuestions, (index) {
              final isCompleted = index < currentQuestion - 1;
              final isCurrent = index == currentQuestion - 1;
              
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.primaryLight
                      : isCurrent
                          ? AppTheme.primaryLight.withOpacity(0.7)
                          : isDark 
                              ? Colors.grey[600] 
                              : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class QuizCompletionProgressWidget extends StatelessWidget {
  final int answeredQuestions;
  final int totalQuestions;
  final bool isDark;

  const QuizCompletionProgressWidget({
    super.key,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = answeredQuestions / totalQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '$answeredQuestions / $totalQuestions',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
