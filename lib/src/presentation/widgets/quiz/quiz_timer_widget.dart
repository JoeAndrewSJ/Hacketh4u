import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuizTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const QuizTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isLowTime = remainingSeconds <= 60; // Less than 1 minute
    final isCriticalTime = remainingSeconds <= 30; // Less than 30 seconds

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCriticalTime 
            ? Colors.red.withOpacity(0.9)
            : isLowTime 
                ? Colors.orange.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isCriticalTime 
                ? Colors.white
                : isLowTime 
                    ? Colors.white
                    : AppTheme.primaryLight,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isCriticalTime 
                  ? Colors.white
                  : isLowTime 
                      ? Colors.white
                      : AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizTimerProgressWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const QuizTimerProgressWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final isLowTime = remainingSeconds <= 60;
    final isCriticalTime = remainingSeconds <= 30;

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isCriticalTime 
                ? Colors.red
                : isLowTime 
                    ? Colors.orange
                    : AppTheme.primaryLight,
          ),
        ),
      ),
    );
  }
}
