import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../common/widgets.dart';
import '../common/video_delete_dialog.dart';

class VideoEditDialog extends StatefulWidget {
  final Map<String, dynamic> video;
  final String courseId;
  final String moduleId;
  final Function(Map<String, dynamic>) onUpdate;
  final Function(String) onDelete;

  const VideoEditDialog({
    super.key,
    required this.video,
    required this.courseId,
    required this.moduleId,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<VideoEditDialog> createState() => _VideoEditDialogState();
}

class _VideoEditDialogState extends State<VideoEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.video['description'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Edit Video'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video Title
            CustomTextField(
              controller: _titleController,
              label: 'Video Title',
              hint: 'Enter video title',
              prefixIcon: const Icon(Icons.title),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a video title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Video Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Enter video description',
              prefixIcon: const Icon(Icons.description),
              isTextArea: true,
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Video Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Information',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Duration', _formatDuration(widget.video['duration'] ?? 0)),
                  _buildInfoRow('File Size', _formatFileSize(widget.video['fileSize'] ?? 0)),
                  _buildInfoRow('Status', widget.video['status'] ?? 'unknown'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _deleteVideo,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateVideo,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  void _updateVideo() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a video title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedVideo = Map<String, dynamic>.from(widget.video);
    updatedVideo['title'] = _titleController.text.trim();
    updatedVideo['description'] = _descriptionController.text.trim();

    widget.onUpdate(updatedVideo);
    Navigator.pop(context);
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) => VideoDeleteDialog(
        videoTitle: widget.video['title'] ?? 'Untitled Video',
        videoId: widget.video['id'],
        onConfirm: () {
          Navigator.pop(context); // Close edit dialog
          widget.onDelete(widget.video['id']);
        },
        onCancel: () {
          // Dialog will close automatically
        },
      ),
    );
  }
}
