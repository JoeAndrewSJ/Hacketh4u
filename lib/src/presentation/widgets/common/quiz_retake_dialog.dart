import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuizRetakeDialog extends StatelessWidget {
  final String quizTitle;
  final int currentAttempt;
  final int maxAttempts;
  final int remainingAttempts;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const QuizRetakeDialog({
    super.key,
    required this.quizTitle,
    required this.currentAttempt,
    required this.maxAttempts,
    required this.remainingAttempts,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.95 : 400,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quiz Icon
              Container(
                width: isSmallScreen ? 70 : 80,
                height: isSmallScreen ? 70 : 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: isSmallScreen ? 35 : 40,
                  color: AppTheme.primaryLight,
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Title
              Text(
                'Retake Quiz',
                style: AppTextStyles.h2.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Description
              Text(
                'Are you sure you want to retake this quiz?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 6 : 8),

              // Quiz Title (highlighted)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                    ? AppTheme.surfaceLight.withOpacity(0.1)
                    : AppTheme.surfaceDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      size: isSmallScreen ? 18 : 20,
                      color: AppTheme.primaryLight,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        quizTitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Attempt Information
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: isSmallScreen ? 18 : 20,
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Text(
                            'This will be attempt ${currentAttempt + 1} of $maxAttempts',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (remainingAttempts > 0) ...[
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            color: Colors.blue[600],
                            size: isSmallScreen ? 18 : 20,
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Text(
                              'You will have $remainingAttempts ${remainingAttempts == 1 ? 'attempt' : 'attempts'} remaining after this',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Action Buttons
              if (isSmallScreen)
                // Stacked buttons for very small screens
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryLight,
                              AppTheme.primaryLight.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm();
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
                            children: [
                              const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start Retake',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                          ),
                        ),
                        child: TextButton(
                          onPressed: onCancel ?? () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Side-by-side buttons for normal screens
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                          ),
                        ),
                        child: TextButton(
                          onPressed: onCancel ?? () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryLight,
                              AppTheme.primaryLight.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm();
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
                            children: [
                              const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Start Retake',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
