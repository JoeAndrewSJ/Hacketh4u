import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';

class QuizResultSummaryWidget extends StatelessWidget {
  final QuizModel quiz;
  final QuizAttempt attempt;
  final bool canRetake;
  final int remainingAttempts;
  final bool isDark;
  final VoidCallback onRetake;

  const QuizResultSummaryWidget({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.canRetake,
    required this.remainingAttempts,
    required this.isDark,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: attempt.isPassed
              ? [Colors.green.shade400, Colors.green.shade500]
              : [Colors.orange.shade400, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Result Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              attempt.isPassed ? Icons.check_circle_outline : Icons.error_outline,
              size: 32,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Result Text and Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.isPassed ? 'Quiz Passed!' : 'Try Again',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attempt.answers.where((a) => a.isCorrect).length} / ${attempt.answers.length} questions correct',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Score Percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${attempt.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultStatsWidget extends StatelessWidget {
  final QuizAttempt attempt;
  final bool isDark;

  const QuizResultStatsWidget({
    super.key,
    required this.attempt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = attempt.answers.where((a) => a.isCorrect).length;
    final incorrectAnswers = attempt.answers.where((a) => !a.isCorrect).length;
    final totalTime = attempt.answers.fold<int>(
      0, (sum, answer) => sum + (answer.timeSpentSeconds ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Flat horizontal stats list
          Row(
            children: [
              Expanded(
                child: _buildFlatStatCard(
                  'Correct',
                  correctAnswers.toString(),
                  Icons.check_circle,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlatStatCard(
                  'Incorrect',
                  incorrectAnswers.toString(),
                  Icons.cancel,
                  Colors.red,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlatStatCard(
                  'Time',
                  _formatDuration(totalTime),
                  Icons.timer,
                  AppTheme.primaryLight,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlatStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark 
                      ? AppTheme.textSecondaryDark 
                      : AppTheme.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}