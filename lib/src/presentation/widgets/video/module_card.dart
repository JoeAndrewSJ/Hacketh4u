import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'video_list_item.dart';

class ModuleCard extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<Map<String, dynamic>> videos;
  final bool isExpanded;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String videoId)? onVideoTap;
  final void Function(String videoId)? onVideoEdit;
  final void Function(String videoId)? onVideoDelete;
  final void Function(String videoId)? onVideoCreate;

  const ModuleCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.videos,
    this.isExpanded = false,
    this.isAdmin = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onVideoTap,
    this.onVideoEdit,
    this.onVideoDelete,
    this.onVideoCreate,
  });

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module Header
          _buildModuleHeader(context),
          
          // Videos List (Expandable)
          if (_isExpanded) _buildVideosList(context),
        ],
      ),
    );
  }

  Widget _buildModuleHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDuration = _calculateTotalDuration();
    final completedVideos = widget.videos.where((v) => v['isCompleted'] == true).length;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Module Icon and Progress
              _buildModuleIcon(context),
              const SizedBox(width: 16),
              
              // Module Info
              Expanded(
                child: _buildModuleInfo(context, totalDuration, completedVideos),
              ),
              
              // Expand/Collapse Icon
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                size: 24,
              ),
              
              // Admin Actions
              if (widget.isAdmin) ...[
                const SizedBox(width: 8),
                _buildAdminActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedVideos = widget.videos.where((v) => v['isCompleted'] == true).length;
    final progress = widget.videos.isEmpty ? 0.0 : completedVideos / widget.videos.length;
    
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppTheme.primaryLight,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${widget.order}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (progress > 0)
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : AppTheme.primaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModuleInfo(BuildContext context, int totalDuration, int completedVideos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module Title
        Text(
          widget.title,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        
        // Module Description
        Text(
          widget.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // Module Stats
        Row(
          children: [
            Icon(
              Icons.video_library,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.videos.length} videos',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.access_time,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(totalDuration),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            if (completedVideos > 0) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '$completedVideos completed',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add Video Button
        GestureDetector(
          onTap: widget.onVideoCreate != null ? () => widget.onVideoCreate!(widget.id) : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: AppTheme.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Edit Module Button
        GestureDetector(
          onTap: widget.onEdit,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit,
              size: 18,
              color: AppTheme.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Delete Module Button
        GestureDetector(
          onTap: widget.onDelete,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.delete,
              size: 18,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideosList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark.withOpacity(0.5) : AppTheme.backgroundLight.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Videos Header
          Row(
            children: [
              Text(
                'Videos',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.videos.length} videos',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Videos List
          if (widget.videos.isEmpty)
            _buildEmptyVideosState(context)
          else
            ...widget.videos.asMap().entries.map((entry) {
              final index = entry.key;
              final video = entry.value;
              
              return VideoListItem(
                id: video['id'] ?? '',
                title: video['title'] ?? '',
                description: video['description'] ?? '',
                thumbnailUrl: video['thumbnailUrl'],
                duration: video['duration'] ?? 0,
                order: index + 1,
                isCompleted: video['isCompleted'] ?? false,
                isCurrentlyPlaying: video['isCurrentlyPlaying'] ?? false,
                isAdmin: widget.isAdmin,
                onTap: widget.onVideoTap != null ? () => widget.onVideoTap!(video['id']) : null,
                onEdit: widget.onVideoEdit != null ? () => widget.onVideoEdit!(video['id']) : null,
                onDelete: widget.onVideoDelete != null ? () => widget.onVideoDelete!(video['id']) : null,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyVideosState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No videos yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add videos to this module to get started',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onVideoCreate != null ? () => widget.onVideoCreate!(widget.id) : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _calculateTotalDuration() {
    return widget.videos.fold(0, (total, video) => total + ((video['duration'] ?? 0) as int));
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
