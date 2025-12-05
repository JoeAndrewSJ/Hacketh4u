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
    final isSmallScreen = screenWidth < 360;
    final isTinyScreen = screenWidth < 320;

    // Set card width to be responsive (e.g., 40% of screen width for horizontal scroll)
    // Or use null to let parent (GridView) control the width
    final cardWidth = useFixedWidth
        ? (isTinyScreen ? screenWidth * 0.44 : (isSmallScreen ? screenWidth * 0.42 : screenWidth * 0.4))
        : screenWidth * 0.45;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: useFixedWidth ? cardWidth : null, // Conditional width: fixed or parent-controlled
        margin: EdgeInsets.symmetric(
          horizontal: isTinyScreen ? 2 : 3,
          vertical: useFixedWidth ? (isSmallScreen ? 6 : 8) : 2, // Minimal vertical margin in GridView
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Compact size
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Star Rating Overlay
            _buildThumbnailSection(context, cardWidth, isSmallScreen, isTinyScreen),

            // Course Details
            _buildCourseInfo(context, cardWidth, isSmallScreen, isTinyScreen),

            // Admin Actions (if applicable)
            if (isAdmin) _buildAdminActions(context, cardWidth, isSmallScreen, isTinyScreen),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildThumbnailSection(BuildContext context, double cardWidth, bool isSmallScreen, bool isTinyScreen) {
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
        _buildStarRating(isSmallScreen, isTinyScreen),
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

  Widget _buildStarRating(bool isSmallScreen, bool isTinyScreen) {
    return Positioned(
      top: isTinyScreen ? 6 : (isSmallScreen ? 8 : 10),
      left: isTinyScreen ? 6 : (isSmallScreen ? 8 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTinyScreen ? 5 : (isSmallScreen ? 6 : 8),
          vertical: isTinyScreen ? 2 : (isSmallScreen ? 3 : 4),
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6), // Rectangular with slight rounding
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
            ),
            SizedBox(width: isTinyScreen ? 2 : (isSmallScreen ? 3 : 4)),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo(BuildContext context, double cardWidth, bool isSmallScreen, bool isTinyScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        useFixedWidth ? (isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)) : 10,
        useFixedWidth ? (isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)) : 8,
        useFixedWidth ? (isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)) : 10,
        useFixedWidth ? (isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)) : 8,
      ), // Compact padding in GridView
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
              fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : (cardWidth < 250 ? 13 : 15)),
            ),
            maxLines: isTinyScreen ? 1 : 2, // Single line for tiny screens
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: useFixedWidth ? (isTinyScreen ? 4 : (isSmallScreen ? 5 : 6)) : 3),

          // Course Description
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.8),
              fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : (cardWidth < 250 ? 10 : 11)),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: useFixedWidth ? (isTinyScreen ? 5 : (isSmallScreen ? 6 : 8)) : 5),

          // Metadata Row
          Wrap(
            spacing: isTinyScreen ? 8 : 10,
            runSpacing: 4,
            children: [
              _buildMetadataItem(Icons.access_time_filled, duration, isSmallScreen, isTinyScreen),
              _buildMetadataItem(Icons.people_alt_rounded, '$studentCount', isSmallScreen, isTinyScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String text, bool isSmallScreen, bool isTinyScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isTinyScreen ? 11 : (isSmallScreen ? 12 : 14),
          color: Colors.grey[600],
        ),
        SizedBox(width: isTinyScreen ? 3 : 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : 12),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context, double cardWidth, bool isSmallScreen, bool isTinyScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12),
        vertical: isTinyScreen ? 6 : (isSmallScreen ? 8 : 10),
      ),
      child: Row(
        children: [
          // Edit Button
          Expanded(
            child: TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 6 : 8),
              ),
              icon: Icon(
                Icons.edit_note_rounded,
                size: isTinyScreen ? 12 : (isSmallScreen ? 13 : 14),
                color: AppTheme.primaryLight,
              ),
              label: Text(
                'EDIT',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : (cardWidth < 250 ? 11 : 12)),
                ),
              ),
            ),
          ),
          SizedBox(width: isTinyScreen ? 6 : 8),
          // Delete Button
          Expanded(
            child: TextButton.icon(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 6 : 8),
              ),
              icon: Icon(
                Icons.delete_forever_rounded,
                size: isTinyScreen ? 12 : (isSmallScreen ? 13 : 14),
                color: Colors.red,
              ),
              label: Text(
                'DELETE',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : (cardWidth < 250 ? 11 : 12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}