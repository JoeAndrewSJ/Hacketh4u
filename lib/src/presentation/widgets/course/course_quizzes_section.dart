import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../core/di/service_locator.dart';
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
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),

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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              height: 1.3,
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
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Premium',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: Colors.amber,
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
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

  void _startQuiz(BuildContext context, QuizModel quiz) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marksPerQuestion = quiz.questions.isNotEmpty ? (quiz.totalMarks / quiz.questions.length).toStringAsFixed(1) : '0';

    // Fetch user's quiz result summary
    QuizResultSummary? summary;
    try {
      final quizRepository = sl<QuizRepository>();
      summary = await quizRepository.getUserQuizResultSummary(quiz.id);
    } catch (e) {
      print('Error fetching quiz summary: $e');
    }

    // Debug: Print summary data
    if (summary != null) {
      print('CourseQuizzesSection: Quiz Summary for ${quiz.title}:');
      print('  - Total Attempts: ${summary.totalAttempts}/${quiz.maxAttempts}');
      print('  - Best Score: ${summary.bestMarks}/${quiz.totalMarks}');
      print('  - Best Percentage: ${summary.bestPercentage.toStringAsFixed(1)}%');
      print('  - Has Passed: ${summary.hasPassed}');
      print('  - Can Retake: ${summary.canRetake}');
      print('  - Remaining Attempts: ${summary.remainingAttempts}');
    }

    // Check if user has reached max attempts
    if (summary != null && !summary.canRetake && summary.remainingAttempts == 0) {
      if (!context.mounted) return;
      _showMaxAttemptsReachedDialog(context, quiz, summary, isDark);
      return;
    }

    if (!context.mounted) return;
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
              // Quiz Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.quiz_rounded,
                          size: 26,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Start Quiz',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF9E9E9E),
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
                    Text(
                      quiz.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),

                    // Quiz Description
                    if (quiz.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        quiz.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                          color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                          height: 1.6,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Key Quiz Info - Grid Layout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // First Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleInfoItem(
                                  Icons.help_outline_rounded,
                                  '${quiz.questions.length}',
                                  'Questions',
                                  isDark,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                              ),
                              Expanded(
                                child: _buildSimpleInfoItem(
                                  Icons.stars_rounded,
                                  '${quiz.totalMarks}',
                                  'Total Marks',
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                            ),
                          ),
                          // Second Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimpleInfoItem(
                                  Icons.calculate_rounded,
                                  marksPerQuestion,
                                  'Per Question',
                                  isDark,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                              ),
                              Expanded(
                                child: _buildSimpleInfoItem(
                                  Icons.flag_rounded,
                                  '${quiz.passingScore}%',
                                  'Passing Score',
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          // Time Limit
                          if (quiz.timeLimitMinutes != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                height: 1,
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            _buildSimpleInfoItem(
                              Icons.timer_outlined,
                              '${quiz.timeLimitMinutes} min',
                              'Time Limit',
                              isDark,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Best Score Display (if user has taken the quiz before)
                    if (summary != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: summary.hasPassed
                                ? [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)]
                                : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: summary.hasPassed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  summary.hasPassed ? Icons.emoji_events : Icons.replay_rounded,
                                  color: summary.hasPassed ? Colors.green : Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your Best Score',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: summary.hasPassed ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${summary.bestPercentage.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildScoreStat(
                                    'Score',
                                    '${summary.bestMarks}/${quiz.totalMarks}',
                                    isDark,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                Expanded(
                                  child: _buildScoreStat(
                                    'Attempts',
                                    '${summary.totalAttempts}/${quiz.maxAttempts}',
                                    isDark,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                Expanded(
                                  child: _buildScoreStat(
                                    'Status',
                                    summary.hasPassed ? 'Passed' : 'Not Passed',
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

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
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: AppTheme.primaryLight.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    summary != null ? 'Retake Quiz' : 'Start Quiz',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoItem(IconData icon, String value, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  void _showMaxAttemptsReachedDialog(BuildContext context, QuizModel quiz, QuizResultSummary summary, bool isDark) {
    print('_showMaxAttemptsReachedDialog: Displaying popup with:');
    print('  - Best Marks: ${summary.bestMarks}/${quiz.totalMarks}');
    print('  - Best Percentage: ${summary.bestPercentage.toStringAsFixed(1)}%');
    print('  - Has Passed: ${summary.hasPassed}');

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
              // Header with Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.1),
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
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Maximum Attempts Reached',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'You have used all ${quiz.maxAttempts} ${quiz.maxAttempts == 1 ? "attempt" : "attempts"} for this quiz.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Best Score Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: summary.hasPassed
                              ? [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)]
                              : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: summary.hasPassed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                summary.hasPassed ? Icons.emoji_events : Icons.info_outline,
                                color: summary.hasPassed ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your Best Score',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // _buildScoreStat(
                              //   'Score',
                              //   '${summary.bestMarks}/${quiz.totalMarks}',
                              //   isDark,
                              // ),
                              _buildScoreStat(
                                'Percentage',
                                '${summary.bestPercentage.toStringAsFixed(1)}%',
                                isDark,
                              ),
                              _buildScoreStat(
                                'Status',
                                summary.hasPassed ? 'Passed' : 'Failed',
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppTheme.primaryLight.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Got It',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
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
}
