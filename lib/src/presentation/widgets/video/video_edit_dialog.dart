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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.95 : 420,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 48 : 56,
                    height: isSmallScreen ? 48 : 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.edit_rounded,
                        size: isSmallScreen ? 24 : 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Video',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update video details',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title Field
                    CustomTextField(
                      controller: _titleController,
                      label: 'Video Title',
                      hint: 'Enter video title',
                      prefixIcon: const Icon(Icons.title_rounded),
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
                      prefixIcon: const Icon(Icons.description_rounded),
                      isTextArea: true,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    // Video Info Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.withOpacity(0.1),
                            Colors.purple.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.purple.shade600,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Video Information',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Duration',
                            _formatDuration(widget.video['duration'] ?? 0),
                            Icons.access_time_rounded,
                            isSmallScreen,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'File Size',
                            _formatFileSize(widget.video['fileSize'] ?? 0),
                            Icons.storage_rounded,
                            isSmallScreen,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Status',
                            widget.video['status'] ?? 'unknown',
                            Icons.check_circle_outline_rounded,
                            isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Delete Button
                  Container(
                    height: isSmallScreen ? 44 : 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _deleteVideo,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Cancel & Save Buttons
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: isSmallScreen ? 44 : 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                                width: 1.5,
                              ),
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: isSmallScreen ? 44 : 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateVideo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.purple.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
