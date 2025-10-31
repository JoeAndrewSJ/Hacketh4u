import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../../data/models/quiz_model.dart';
import '../../widgets/quiz/quiz_result_summary_widget.dart';
import '../../widgets/quiz/quiz_result_details_widget.dart';
import 'quiz_taking_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final String courseId;
  final QuizModel quiz;
  final QuizAttempt attempt;

  const QuizResultScreen({
    super.key,
    required this.courseId,
    required this.quiz,
    required this.attempt,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _canRetake = true;
  int _remainingAttempts = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkRetakeEligibility();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkRetakeEligibility() {
    setState(() {
      _canRetake = widget.quiz.allowRetake && 
                   widget.attempt.attemptNumber < widget.quiz.maxAttempts;
      _remainingAttempts = widget.quiz.maxAttempts - widget.attempt.attemptNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Quiz Result',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.attempt.isPassed ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          
          
          // Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              labelStyle: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(isDark),
                _buildDetailsTab(isDark),
              ],
            ),
          ),
          
          // Action Buttons
          _buildActionButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(bool isDark) {
    final correctAnswers = widget.attempt.answers.where((a) => a.isCorrect).length;
    final totalQuestions = widget.attempt.answers.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Performance Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.attempt.isPassed 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.attempt.isPassed ? Icons.check_circle : Icons.warning,
                        color: widget.attempt.isPassed ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Performance Overview',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Correct Answers',
                        '$correctAnswers/$totalQuestions',
                        Icons.check_circle,
                        Colors.green,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Percentage',
                        '${widget.attempt.percentage.toStringAsFixed(1)}%',
                        Icons.percent,
                        widget.attempt.isPassed ? Colors.green : Colors.orange,
                        isDark,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    
                    Expanded(
                      child: _buildStatCard(
                        'Status',
                        widget.attempt.isPassed ? 'Passed' : 'Failed',
                        widget.attempt.isPassed ? Icons.emoji_events : Icons.error_outline,
                        widget.attempt.isPassed ? Colors.green : Colors.red,
                        isDark,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Time Information
          if (widget.attempt.completedAt != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Information',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    'Started',
                    _formatDateTime(widget.attempt.startedAt),
                    Icons.play_arrow,
                    isDark,
                  ),
                  _buildInfoRow(
                    'Completed',
                    _formatDateTime(widget.attempt.completedAt!),
                    Icons.check_circle,
                    isDark,
                  ),
                  _buildInfoRow(
                    'Duration',
                    _formatDuration(widget.attempt.startedAt, widget.attempt.completedAt!),
                    Icons.timer,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(bool isDark) {
    return QuizResultDetailsWidget(
      quiz: widget.quiz,
      attempt: widget.attempt,
      isDark: isDark,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                side: BorderSide(color: AppTheme.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Back to Course'),
            ),
          ),
          
          if (_canRetake) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _retakeQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Retake Quiz'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _retakeQuiz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake Quiz'),
        content: Text(
          'Are you sure you want to retake this quiz? This will be attempt ${widget.attempt.attemptNumber + 1} of ${widget.quiz.maxAttempts} allowed attempts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Reset quiz state
              context.read<QuizBloc>().add(const ResetQuizState());
              
              // Navigate to quiz taking screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizTakingScreen(
                    courseId: widget.courseId,
                    quizId: widget.quiz.id,
                    quiz: widget.quiz,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Retake'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
