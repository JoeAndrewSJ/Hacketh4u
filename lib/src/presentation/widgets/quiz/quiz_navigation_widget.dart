import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuizNavigationWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final bool isLastQuestion;
  final bool hasAnswer;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final bool isDark;

  const QuizNavigationWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.isLastQuestion,
    required this.hasAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: OutlinedButton(
                onPressed: currentQuestion > 1 ? onPrevious : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentQuestion > 1 
                      ? AppTheme.primaryLight 
                      : Colors.grey,
                  side: BorderSide(
                    color: currentQuestion > 1 
                        ? AppTheme.primaryLight 
                        : Colors.grey,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text('Previous'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next/Submit Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: hasAnswer ? (isLastQuestion ? onSubmit : onNext) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastQuestion 
                      ? (hasAnswer ? Colors.green : Colors.grey)
                      : (hasAnswer ? AppTheme.primaryLight : Colors.grey),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastQuestion ? 'Submit Quiz' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastQuestion ? Icons.check_circle : Icons.arrow_forward_ios,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizSubmitConfirmationWidget extends StatelessWidget {
  final int answeredQuestions;
  final int totalQuestions;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isDark;

  const QuizSubmitConfirmationWidget({
    super.key,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.onSubmit,
    required this.onCancel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final unansweredQuestions = totalQuestions - answeredQuestions;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Submit Quiz?',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'You have answered $answeredQuestions out of $totalQuestions questions.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          
          if (unansweredQuestions > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$unansweredQuestions question${unansweredQuestions > 1 ? 's' : ''} remain unanswered. These will be marked as incorrect.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: BorderSide(color: AppTheme.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Continue Quiz'),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Submit Quiz'),
                ),
              ),
            ],
          ),
          
          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
