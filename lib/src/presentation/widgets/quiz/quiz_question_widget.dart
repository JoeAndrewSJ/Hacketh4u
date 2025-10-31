import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';

class QuizQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedAnswerIndex;
  final Function(int) onAnswerSelected;
  final bool isDark;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswerIndex,
    required this.onAnswerSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                _getQuestionText(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Answer Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = selectedAnswerIndex == index;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildAnswerOption(index, option, isSelected),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getQuestionText() {
    // Handle case where questionText might be a Map or other object
    if (question.questionText is Map) {
      return question.questionText.toString();
    } else {
      return question.questionText?.toString() ?? 'No question text available';
    }
  }

  Widget _buildAnswerOption(int index, dynamic option, bool isSelected) {
    return GestureDetector(
      onTap: () => onAnswerSelected(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryLight
                : (isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.5)),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Option Text
            Expanded(
              child: Text(
                option?.toString() ?? 'No option text',
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.white : Colors.black),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.grey.withOpacity(0.5) : Colors.grey.withOpacity(0.7)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppTheme.primaryLight,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
