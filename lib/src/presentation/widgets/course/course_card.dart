import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CourseCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double rating;
  final int studentCount;
  final String duration;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool useFixedWidth; // New parameter to control fixed width behavior

  const CourseCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.rating,
    required this.studentCount,
    required this.duration,
    this.isAdmin = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.useFixedWidth = true, // Default to true to maintain existing behavior
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Set card width to be responsive (e.g., 40% of screen width for horizontal scroll)
    // Or use null to let parent (GridView) control the width
    final cardWidth = useFixedWidth ? screenWidth * 0.4 : screenWidth * 0.45;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: useFixedWidth ? cardWidth : null, // Conditional width: fixed or parent-controlled
        margin: EdgeInsets.symmetric(
          horizontal: 3,
          vertical: useFixedWidth ? 8 : 4, // Less vertical margin in GridView
        ),
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
          mainAxisSize: MainAxisSize.min, // Prevent column from expanding
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Star Rating Overlay
            _buildThumbnailSection(context, cardWidth),

            // Course Details
            _buildCourseInfo(context, cardWidth),

            // Admin Actions (if applicable)
            if (isAdmin) _buildAdminActions(context, cardWidth),
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
          child: SizedBox(
            width: double.infinity, // Take full width of parent container
            height: cardWidth * 0.65, // Balanced height that fits within card constraints
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
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6), // Rectangular with slight rounding
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo(BuildContext context, double cardWidth) {
    return Padding(
      padding: EdgeInsets.all(useFixedWidth ? 12 : 10), // Less padding in GridView
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Title
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: FontWeight.w700,
              fontSize: cardWidth < 250 ? 14 : 16, // Smaller font in GridView
            ),
            maxLines: 1, // Changed from 2 to 1 to keep title on single line
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: useFixedWidth ? 6 : 4), // Less spacing in GridView

          // Course Description
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.8),
              fontSize: cardWidth < 250 ? 11 : 12, // Smaller font in GridView
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: useFixedWidth ? 8 : 6), // Less spacing in GridView

          // Metadata Row
          Row(
            children: [
              _buildMetadataItem(Icons.access_time_filled, duration),
              const SizedBox(width: 12),
              _buildMetadataItem(Icons.people_alt_rounded, '$studentCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context, double cardWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Edit Button
          Expanded(
            child: TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: Icon(Icons.edit_note_rounded, size: 14, color: AppTheme.primaryLight),
              label: Text(
                'EDIT',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: cardWidth < 250 ? 11 : 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          Expanded(
            child: TextButton.icon(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 14, color: Colors.red),
              label: Text(
                'DELETE',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: cardWidth < 250 ? 11 : 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}