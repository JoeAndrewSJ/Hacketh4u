import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VideoListItem extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int duration; // in seconds
  final int order;
  final bool isCompleted;
  final bool isCurrentlyPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const VideoListItem({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.duration,
    required this.order,
    this.isCompleted = false,
    this.isCurrentlyPlaying = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying 
              ? AppTheme.primaryLight
              : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
          width: isCurrentlyPlaying ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Video Thumbnail
                _buildVideoThumbnail(context),
                const SizedBox(width: 16),
                
                // Video Info
                Expanded(
                  child: _buildVideoInfo(context),
                ),
                
                // Status and Actions
                _buildStatusAndActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
            ? Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder(context);
                },
              )
            : _buildThumbnailPlaceholder(context),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight.withOpacity(0.3),
            AppTheme.secondaryLight.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildVideoInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Order and Title
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Description
        Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // Duration
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(duration),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusAndActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Completion Status
        if (isCompleted)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          )
        else if (isCurrentlyPlaying)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 16,
            ),
          )
        else
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Admin Actions
        if (isAdmin)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.delete,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}
