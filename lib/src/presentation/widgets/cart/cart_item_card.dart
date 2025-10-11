import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> cartItem;
  final VoidCallback? onRemove;
  final bool isDark;

  const CartItemCard({
    super.key,
    required this.cartItem,
    this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    print('Cart Item: $cartItem');
    final hasDiscount = cartItem['originalPrice'] > cartItem['price'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Course Thumbnail
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCourseThumbnail(),
            ),
          ),
          const SizedBox(width: 12),

          // Course Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem['title'] ?? 'Unknown Course',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${cartItem['instructor'] ?? cartItem['instructorName'] ?? 'Unknown Instructor'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        '₹${cartItem['originalPrice']?.toStringAsFixed(0) ?? '0'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '₹${cartItem['price']?.toStringAsFixed(0) ?? '0'}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove Button
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseThumbnail() {
    // Try multiple possible thumbnail field names
    final thumbnailUrl = cartItem['thumbnailUrl'] ?? 
                        cartItem['thumbnail'] ?? 
                        cartItem['imageUrl'] ?? 
                        cartItem['courseImage'] ?? 
                        '';
    
    // Validate URL before attempting to load
    if (thumbnailUrl.isNotEmpty && _isValidUrl(thumbnailUrl)) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Image load error: $error');
          print('Thumbnail URL: $thumbnailUrl');
          return _buildPlaceholderThumbnail();
        },
      );
    }
    
    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.play_circle_outline,
        color: Colors.grey[600],
        size: 30,
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
