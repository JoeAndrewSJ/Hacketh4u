import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VideoListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final bool isDark;
  final Function(Map<String, dynamic>)? onVideoTap;
  final Function(Map<String, dynamic>)? onPremiumTap;
  final String? selectedVideoId;
  final bool isParentModulePremium;
  final bool hasCourseAccess;
  final String? courseId;
  final String? moduleId;
  final Map<String, double>? videoProgress; // videoId -> watchPercentage

  const VideoListWidget({
    super.key,
    required this.videos,
    required this.isDark,
    this.onVideoTap,
    this.onPremiumTap,
    this.selectedVideoId,
    this.isParentModulePremium = false,
    this.hasCourseAccess = false,
    this.courseId,
    this.moduleId,
    this.videoProgress,
  });

  @override
  State<VideoListWidget> createState() => _VideoListWidgetState();
}

class _VideoListWidgetState extends State<VideoListWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return _buildEmptyState();
    }

    return _buildVideoList();
  }

  void _onVideoTap(int index, Map<String, dynamic> video) {
    // Videos inherit premium status from their parent module
    final isPremium = widget.isParentModulePremium;

    // If user has course access, they can access all videos
    // If no course access, only free videos are accessible
    final hasAccess = !isPremium || widget.hasCourseAccess;

    // Ensure moduleId is set on the video
    if (widget.moduleId != null) {
      video['moduleId'] = widget.moduleId;
    }

    if (hasAccess) {
      // Call the original callback to play video inline
      widget.onVideoTap?.call(video);
    } else {
      // Show premium lock dialog for premium videos without access
      widget.onPremiumTap?.call(video);
    }
  }


  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 48,
                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No videos available',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Videos will be added soon',
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        final videoId = video['id'];
        final isSelected = widget.selectedVideoId == videoId;
        // Videos inherit premium status from their parent module
        final isPremium = widget.isParentModulePremium;
        final hasAccess = !isPremium || widget.hasCourseAccess;
        final duration = video['duration'] ?? 0;
        final watchPercentage = widget.videoProgress?[videoId] ?? 0.0;
        final isCompleted = watchPercentage >= 100.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight.withOpacity(0.08)
                : widget.isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryLight
                  : widget.isDark ? Colors.grey[700]!.withOpacity(0.3) : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: hasAccess ? 1.0 : 0.6, // Dim locked content
            child: InkWell(
              onTap: hasAccess ? () => _onVideoTap(index, video) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Video thumbnail/icon - different for playing/completed/normal states
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight.withOpacity(0.15)
                          : isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.primaryLight,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isSelected
                            ? Icons.play_circle_filled_rounded
                            : isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.play_circle_outline_rounded,
                        color: isSelected
                            ? AppTheme.primaryLight
                            : isCompleted
                                ? Colors.green
                                : const Color(0xFF424242),
                        size: isSelected ? 32 : 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Video info - wrapped in Flexible to prevent overflow
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          video['title'] ?? 'Untitled Video',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primaryLight
                                : (widget.isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A)),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(duration),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                                  ),
                                ),
                              ],
                            ),
                            if (isPremium && !hasAccess)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Premium',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right side indicator - time and status
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Duration
                      Text(
                        _formatDuration(duration),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status indicator
                      if (isSelected)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.play_arrow_rounded,
                              color: AppTheme.primaryLight,
                              size: 16,
                            ),
                          ],
                        )
                      else if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        )
                      else if (watchPercentage > 0)
                        Text(
                          '${watchPercentage.toInt()}%',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
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
