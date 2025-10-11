import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'video_player_widget.dart';
import '../../screens/video/video_player_screen.dart';

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
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos available',
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
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
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryLight.withOpacity(0.1)
                : widget.isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryLight
                  : widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: hasAccess ? 1.0 : 0.6, // Dim locked content
            child: InkWell(
              onTap: hasAccess ? () => _onVideoTap(index, video) : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Video thumbnail/icon
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green.withOpacity(0.3)
                          : hasAccess 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: [
                        // Main icon
                        Center(
                          child: Icon(
                            hasAccess 
                                ? Icons.play_circle 
                                : Icons.lock,
                            color: hasAccess 
                                ? Colors.green 
                                : Colors.amber,
                            size: 24,
                          ),
                        ),
                        // Progress indicator for partially watched videos
                        if (!isCompleted && watchPercentage > 0)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: watchPercentage / 100.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Completed badge
                        if (isCompleted)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Video info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title'] ?? 'Untitled Video',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(duration),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                            ),
                            if (isPremium && !hasAccess) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Premium',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryLight,
                      size: 20,
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
