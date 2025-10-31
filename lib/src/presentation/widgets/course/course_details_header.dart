import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CourseDetailsHeader extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDark;

  const CourseDetailsHeader({
    super.key,
    required this.course,
    required this.isDark,
  });

  // Helper method to get a value or a default
  T _getValue<T>(String key, T defaultValue) {
    return course[key] is T ? course[key] : defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350, // INCREASED HEIGHT for more content
      pinned: true,
      // Change color for a seamless look, or keep original
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
      foregroundColor: Colors.white, // Ensures icons/text are white on the primary color app bar

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 16, left: 16),
        // Title appears when collapsed (Fallback for course title)
        title: Text(
          _getValue<String>('title', 'Course Details'),
          style: TextStyle(
            color: Colors.white, // Always white on the primary color bar
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Course Thumbnail
            _buildThumbnail(),
            // Gradient Overlay
            _buildGradientOverlay(),
            // Course Title & Details Overlay
            _buildDetailsOverlay(context), // Renamed from _buildTitleOverlay
          ],
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality coming soon!'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildThumbnail() {
    final thumbnailUrl = _getValue<String>('thumbnailUrl', '');
    
    // Validate URL before attempting to load
    if (thumbnailUrl.isNotEmpty && _isValidUrl(thumbnailUrl)) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderThumbnail();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Thumbnail load error: $error');
          print('Thumbnail URL: $thumbnailUrl');
          return _buildPlaceholderThumbnail();
        },
      );
    }

    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4), // Darken top part for icon visibility
            Colors.transparent,
            Colors.black.withOpacity(0.9), // Stronger darkening at the bottom
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildDetailsOverlay(BuildContext context) {
    final List<String> whatYouWillLearn = _getValue<List<dynamic>>('whatYouWillLearn', []).cast<String>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: kToolbarHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Rating and Review Count
            _buildRatingBar(context),
            const SizedBox(height: 8),

            // Course Title
            Text(
              _getValue<String>('title', 'Course Title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Brief "What You Will Learn" List
            if (whatYouWillLearn.isNotEmpty)
              ...whatYouWillLearn.take(2).map((point) => _buildLearnPoint(point)),

            if (whatYouWillLearn.length > 2)
              _buildLearnPoint('...and much more!'),

            const SizedBox(height: 12),

            // Instructor and Duration Info
            _buildBottomStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context) {
    final double rating = _getValue<double>('averageRating', 0.0);
    final int reviews = _getValue<int>('reviewCount', 0);

    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 16,
          );
        }),
        const SizedBox(width: 8),
        Text(
          '($reviews ratings)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLearnPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.check_circle_outline, // A modern checkmark icon
              color: Colors.greenAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
              ),
              maxLines: 1, // Keep points concise in the header
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: Colors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          'By ${_getValue<String>('instructor', _getValue<String>('instructorName', 'Unknown'))}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.access_time,
          color: Colors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_getValue<int>('totalDuration', 0)),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // --- UTILITY ---

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}