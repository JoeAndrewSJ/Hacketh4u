import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminCourseCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double rating;
  final int studentCount;
  final String duration;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AdminCourseCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.rating,
    required this.studentCount,
    required this.duration,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Set card width to be responsive (e.g., 70% of screen width for horizontal scroll)
    final cardWidth = screenWidth * 0.4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth, // Fixed width for horizontal scrolling
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail with Star Rating Overlay
            _buildThumbnailSection(context, cardWidth),

            // Course Details (Compact for Admin)
            _buildCompactCourseInfo(context, cardWidth),

            // Admin Actions
            _buildAdminActions(context, cardWidth),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildThumbnailSection(BuildContext context, double cardWidth) {
    return Stack(
      children: [
        // Landscape Thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            width: cardWidth,
            height: cardWidth * 0.5, // Slightly shorter for admin cards
            child: thumbnailUrl.isNotEmpty
                ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.1),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),
        ),

        // Star Rating Overlay
        _buildStarRating(),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 12,
            ),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCourseInfo(BuildContext context, double cardWidth) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Course Title (Single Line)
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Course Description (Single Line)
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Compact Metadata Row
          Row(
            children: [
              _buildCompactMetadataItem(Icons.access_time_filled, duration),
              const SizedBox(width: 8),
              _buildCompactMetadataItem(Icons.people_alt_rounded, '$studentCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context, double cardWidth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          // Edit Button
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 10, color: AppTheme.primaryLight),
                    const SizedBox(width: 3),
                    Text(
                      'EDIT',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete Button
          Expanded(
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_forever_rounded, size: 10, color: Colors.red),
                    const SizedBox(width: 3),
                    Text(
                      'DELETE',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
