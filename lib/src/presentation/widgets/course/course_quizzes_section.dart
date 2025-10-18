import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../../data/models/quiz_model.dart';
import '../../screens/quiz/quiz_taking_screen.dart';

class CourseQuizzesSection extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<QuizModel> quizzes;
  final bool isLoading;
  final bool isDark;
  final bool hasCourseAccess;

  const CourseQuizzesSection({
    super.key,
    required this.course,
    required this.quizzes,
    required this.isLoading,
    required this.isDark,
    required this.hasCourseAccess,
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
            'Quizzes',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildQuizzesList(context),
        ],
      ),
    );
  }

  Widget _buildQuizzesList(BuildContext context) {
    return Column(
      children: quizzes.asMap().entries.map((entry) {
        final index = entry.key;
        final quiz = entry.value;
        return _buildQuizItem(context, quiz, index + 1);
      }).toList(),
    );
  }

  Widget _buildQuizItem(BuildContext context, QuizModel quiz, int quizNumber) {
    final isPremium = quiz.isPremium;
    final isFree = !isPremium;
    final questionCount = quiz.questions.length;
    final totalMarks = quiz.totalMarks;
    final canAccess = isFree || hasCourseAccess;
    
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
        onTap: canAccess ? () => _startQuiz(context, quiz) : null,
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
                  canAccess ? Icons.quiz : Icons.lock,
                  color: canAccess ? Colors.blue : Colors.amber,
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
                            'Quiz $quizNumber: ${quiz.title}',
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
                          '$questionCount question${questionCount > 1 ? 's' : ''}',
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
                          '$totalMarks mark${totalMarks > 1 ? 's' : ''}',
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
                canAccess ? Icons.play_arrow : Icons.lock,
                color: canAccess ? Colors.blue : Colors.amber,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizModel quiz) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marksPerQuestion = quiz.questions.isNotEmpty ? (quiz.totalMarks / quiz.questions.length).toStringAsFixed(1) : '0';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quiz Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.quiz_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        quiz.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),

                    // Quiz Description
                    if (quiz.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        quiz.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Key Quiz Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Questions',
                            '${quiz.questions.length}',
                            Icons.help_outline,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Total Marks',
                            '${quiz.totalMarks}',
                            Icons.stars,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Marks/Question',
                            marksPerQuestion,
                            Icons.calculate,
                            Colors.green,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Passing Score',
                            '${quiz.passingScore}%',
                            Icons.flag,
                            Colors.red,
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    // Time Limit
                    if (quiz.timeLimitMinutes != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        'Time Limit',
                        '${quiz.timeLimitMinutes} minutes',
                        Icons.timer,
                        Colors.purple,
                        isDark,
                        fullWidth: true,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                                width: 1.5,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizTakingScreen(
                                      courseId: course['id'],
                                      quizId: quiz.id,
                                      quiz: quiz,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Start Quiz',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color, bool isDark, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
