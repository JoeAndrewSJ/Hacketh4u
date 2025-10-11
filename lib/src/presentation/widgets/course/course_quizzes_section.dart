import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CourseQuizzesSection extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> quizzes;
  final bool isLoading;
  final bool isDark;
  final Function(Map<String, dynamic>) onQuizTap;

  const CourseQuizzesSection({
    super.key,
    required this.course,
    required this.quizzes,
    required this.isLoading,
    required this.isDark,
    required this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quizzes & Assessments',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildQuizzesList(),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    return Column(
      children: quizzes.asMap().entries.map((entry) {
        final index = entry.key;
        final quiz = entry.value;
        return _buildQuizItem(quiz, index + 1);
      }).toList(),
    );
  }

  Widget _buildQuizItem(Map<String, dynamic> quiz, int quizNumber) {
    final isPremium = quiz['isPremium'] ?? false;
    final isFree = !isPremium;
    final questionCount = (quiz['questions'] as List?)?.length ?? 0;
    final totalMarks = quiz['totalMarks'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onQuizTap(quiz),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Quiz Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isFree 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFree ? Icons.quiz : Icons.lock,
                  color: isFree ? Colors.blue : Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Quiz Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quiz $quizNumber: ${quiz['title'] ?? 'Untitled Quiz'}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Premium',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$questionCount questions',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.stars,
                          size: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalMarks marks',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Icon
              Icon(
                isFree ? Icons.play_arrow : Icons.lock,
                color: isFree ? Colors.blue : Colors.amber,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
