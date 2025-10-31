import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../common/widgets.dart';

class CoursePricingSection extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final VoidCallback onAddToCart;
  final bool hasCourseAccess;

  const CoursePricingSection({
    super.key,
    required this.course,
    required this.isDark,
    required this.onAddToCart,
    this.hasCourseAccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final strikePrice = course['strikePrice']?.toDouble() ?? 0.0;
    final currentPrice = course['price']?.toDouble() ?? 0.0;
    final isPriceStrikeEnabled = course['isPriceStrikeEnabled'] ?? false;
    final hasDiscount = isPriceStrikeEnabled && strikePrice > currentPrice && strikePrice > 0;
    final discountPercentage = hasDiscount 
        ? ((strikePrice - currentPrice) / strikePrice * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCourseAccess ? 'Course Features' : 'Course Pricing',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Price Section (only show if user doesn't have course access)
                if (!hasCourseAccess) ...[
                  _buildPriceSection(strikePrice, currentPrice, hasDiscount, discountPercentage),
                  const SizedBox(height: 20),
                ],
                
                // Features List
                _buildFeaturesList(),
                const SizedBox(height: 24),
                
                // Add to Cart Button
                _buildAddToCartButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double strikePrice, double currentPrice, bool hasDiscount, int discountPercentage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiscount) ...[
                Text(
                  '₹${strikePrice.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                '₹${currentPrice.toStringAsFixed(0)}',
                style: AppTextStyles.h2.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$discountPercentage% OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureItem(
          icon: Icons.video_library,
          text: '${course['moduleCount'] ?? 0} Modules with Video Content',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.quiz,
          text: '${(course['quizzes'] as List?)?.length ?? 0} Interactive Quizzes',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.verified,
          text: 'Certificate of Completion',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.access_time,
          text: 'Lifetime Access',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.mobile_friendly,
          text: 'Mobile & Desktop Access',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    final currentPrice = course['price']?.toDouble() ?? 0.0;
    
    // If user has course access, show access status instead of enroll button
    if (hasCourseAccess) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: CustomButton(
          text: 'Course Purchased',
          onPressed: null, // Disabled button
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CustomButton(
        text: 'Enroll Now - ₹${currentPrice.toStringAsFixed(0)}',
        onPressed: onAddToCart,
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.school,
          color: Colors.white,
        ),
      ),
    );
  }
}
