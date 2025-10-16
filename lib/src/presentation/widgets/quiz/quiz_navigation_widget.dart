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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            if (currentQuestion > 1)
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPrevious,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_ios,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Previous',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            if (currentQuestion > 1) const SizedBox(width: 16),
            
            // Next/Submit Button
            Expanded(
              flex: currentQuestion > 1 ? 2 : 1,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: hasAnswer 
                      ? (isLastQuestion ? Colors.green : AppTheme.primaryLight)
                      : (isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: hasAnswer ? [
                    BoxShadow(
                      color: (isLastQuestion ? Colors.green : AppTheme.primaryLight).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasAnswer ? (isLastQuestion ? onSubmit : onNext) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastQuestion ? 'Submit Quiz' : 'Next',
                            style: TextStyle(
                              color: hasAnswer ? Colors.white : (isDark ? Colors.grey : Colors.grey[600]),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastQuestion ? Icons.check_circle : Icons.arrow_forward_ios,
                            size: 16,
                            color: hasAnswer ? Colors.white : (isDark ? Colors.grey : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
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
