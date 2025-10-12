import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/loading/hackethos_loading_component.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../widgets/video/video_list_item.dart';
import '../../widgets/video/video_edit_dialog.dart';
import '../../widgets/common/video_delete_dialog.dart';

class ModuleCreationScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Map<String, dynamic>? moduleToEdit;

  const ModuleCreationScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.moduleToEdit,
  });

  @override
  State<ModuleCreationScreen> createState() => _ModuleCreationScreenState();
}

class _ModuleCreationScreenState extends State<ModuleCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _moduleType = 'free';
  List<Map<String, dynamic>> _videos = [];
  bool _isExpanded = false;

  bool get isEditMode => widget.moduleToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _initializeFormWithExistingData();
      _loadVideos();
    }
  }

  void _initializeFormWithExistingData() {
    final module = widget.moduleToEdit!;
    _titleController.text = module['title'] ?? '';
    _descriptionController.text = module['description'] ?? '';
    _moduleType = module['type'] ?? 'free';
    
    // Ensure isPremium field is set for existing modules
    if (module['isPremium'] == null && _moduleType == 'premium') {
      // This will be handled when the module is updated
    }
  }

  void _loadVideos() {
    if (isEditMode) {
      context.read<CourseBloc>().add(LoadModuleVideos(
        courseId: widget.courseId,
        moduleId: widget.moduleToEdit!['id'],
      ));
    }
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

    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is ModuleCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Module "${state.module['title']}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is ModuleUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Module "${state.module['title']}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is VideosLoaded) {
          setState(() {
            _videos = state.videos;
          });
        } else if (state is VideoCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVideos();
        } else if (state is VideoDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVideos();
        } else if (state is CourseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditMode ? 'Edit Module' : 'Create Module'),
              backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
              foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
              elevation: 0,
            ),
            body: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                                  isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.video_library,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isEditMode ? 'Edit Module' : 'Create New Module',
                                        style: AppTextStyles.h2.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Course: ${widget.courseTitle}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Module Title
                          CustomTextField(
                            controller: _titleController,
                            label: 'Module Title',
                            hint: 'Enter a descriptive title for this module',
                            prefixIcon: const Icon(Icons.title),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a module title';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Module Description
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Module Description',
                            hint: 'Describe what students will learn in this module',
                            prefixIcon: const Icon(Icons.description),
                            isTextArea: true,
                            maxLines: 4,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Module Type
                          Text(
                            'Module Type',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Free'),
                                  subtitle: const Text('Available to all students'),
                                  value: 'free',
                                  groupValue: _moduleType,
                                  onChanged: (value) {
                                    setState(() {
                                      _moduleType = value!;
                                    });
                                  },
                                  activeColor: AppTheme.primaryLight,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Premium'),
                                  subtitle: const Text('Subscription required'),
                                  value: 'premium',
                                  groupValue: _moduleType,
                                  onChanged: (value) {
                                    setState(() {
                                      _moduleType = value!;
                                    });
                                  },
                                  activeColor: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Videos Section
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Videos (${_videos.length})',
                                  style: AppTextStyles.h3.copyWith(
                                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _uploadVideo,
                                icon: Icon(
                                  Icons.add,
                                  color: isEditMode 
                                    ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)
                                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                ),
                                tooltip: isEditMode ? 'Add Video' : 'Create module first to add videos',
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Videos List
                          if (_videos.isNotEmpty)
                            ...(_videos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final video = entry.value;
                              return VideoListItem(
                                id: video['id'] ?? '',
                                title: video['title'] ?? 'Untitled Video',
                                description: video['description'] ?? '',
                                thumbnailUrl: video['thumbnailUrl'],
                                duration: video['duration'] ?? 0,
                                order: index + 1,
                                isCompleted: video['status'] == 'completed',
                                isCurrentlyPlaying: false,
                                isAdmin: true,
                                onEdit: () => _editVideo(video),
                                onDelete: () => _deleteVideo(video),
                              );
                            }).toList())
                          else
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
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
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEditMode 
                                      ? 'Upload your first video to get started'
                                      : 'Create the module first, then upload videos',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 32),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  onPressed: () => Navigator.of(context).pop(),
                                  isOutlined: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: isEditMode ? 'Update Module' : 'Create Module',
                                  onPressed: _submitModule,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Loading overlay
                if (state.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: HackethosLoadingComponent(
                        message: isEditMode ? 'Updating module...' : 'Creating module...',
                        size: 80,
                        showImage: true,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitModule() {
    if (_formKey.currentState!.validate()) {
      final moduleData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _moduleType,
        'isPremium': _moduleType == 'premium',
        'videoCount': _videos.length,
        'totalDuration': _videos.fold(0, (total, video) => total + ((video['duration'] ?? 0) as int)),
        'order': isEditMode ? (widget.moduleToEdit!['order'] ?? 1) : (_videos.length + 1),
        'status': isEditMode ? (widget.moduleToEdit!['status'] ?? 'active') : 'active',
      };

      if (isEditMode) {
        context.read<CourseBloc>().add(UpdateModule(
          courseId: widget.courseId,
          moduleId: widget.moduleToEdit!['id'],
          moduleData: moduleData,
        ));
      } else {
        context.read<CourseBloc>().add(CreateModule(
          courseId: widget.courseId,
          moduleData: moduleData,
        ));
      }
    }
  }

  void _uploadVideo() {
    if (!isEditMode) {
      // Show snackbar if trying to upload video before creating module
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create the module first before uploading videos'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Create Module',
            textColor: Colors.white,
            onPressed: _submitModule,
          ),
        ),
      );
      return;
    }
    _showVideoUploadDialog();
  }

  void _editVideo(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => VideoEditDialog(
        video: video,
        courseId: widget.courseId,
        moduleId: widget.moduleToEdit?['id'] ?? '',
        onUpdate: (updatedVideo) {
          if (widget.moduleToEdit != null) {
            context.read<CourseBloc>().add(UpdateVideo(
              courseId: widget.courseId,
              moduleId: widget.moduleToEdit!['id'],
              videoId: video['id'],
              videoData: updatedVideo,
            ));
          }
        },
        onDelete: (videoId) {
          _deleteVideo(video);
        },
      ),
    );
  }

  void _deleteVideo(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => VideoDeleteDialog(
        videoTitle: video['title'] ?? 'Untitled Video',
        videoId: video['id'],
        onConfirm: () {
          print('ModuleCreationScreen: Deleting video: ${video['id']}');
          if (widget.moduleToEdit != null) {
            context.read<CourseBloc>().add(DeleteVideo(
              courseId: widget.courseId,
              moduleId: widget.moduleToEdit!['id'],
              videoId: video['id'],
            ));
          }
        },
        onCancel: () {
          // Dialog will close automatically
        },
      ),
    );
  }

  void _showVideoUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => VideoUploadDialog(
        moduleId: isEditMode ? widget.moduleToEdit!['id'] : null,
        courseId: widget.courseId,
        onVideoUploaded: () {
          _loadVideos();
        },
      ),
    );
  }
}

class VideoUploadDialog extends StatefulWidget {
  final String? moduleId;
  final String courseId;
  final VoidCallback? onVideoUploaded;

  const VideoUploadDialog({
    super.key,
    this.moduleId,
    required this.courseId,
    this.onVideoUploaded,
  });

  @override
  State<VideoUploadDialog> createState() => _VideoUploadDialogState();
}

class _VideoUploadDialogState extends State<VideoUploadDialog> {
  File? _selectedVideoFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is VideoCreated && _isUploading) {
          // Video uploaded successfully, close dialog and show success message
          setState(() {
            _isUploading = false;
          });
          widget.onVideoUploaded?.call();
          
          // Close the dialog first
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          // Show success message after a short delay to ensure dialog is closed
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video "${state.video['title']}" uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } else if (state is CourseError && _isUploading) {
          // Show error and reset loading state
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading video: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.video_library,
                  size: 40,
                  color: AppTheme.primaryLight,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Upload Video',
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                      tooltip: 'Close',
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Select a video file to add to this module',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Main content area
              if (_isUploading) 
                _buildUploadingState(isDark)
              else 
                _buildFileSelectionState(isDark),
              
              const SizedBox(height: 24),
              
              // Action buttons
              if (!_isUploading)
                _buildActionButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceLight.withOpacity(0.05) : AppTheme.surfaceDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const HackethosLoadingComponent(
            message: 'Uploading video...',
            size: 60,
            showImage: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Processing video file...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculating duration and generating thumbnail',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionState(bool isDark) {
    return GestureDetector(
      onTap: _selectVideoFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceLight.withOpacity(0.05) : AppTheme.surfaceDark.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedVideoFile != null 
                ? AppTheme.primaryLight.withOpacity(0.3)
                : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _selectedVideoFile != null 
                    ? AppTheme.primaryLight.withOpacity(0.1)
                    : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: _selectedVideoFile != null 
                      ? AppTheme.primaryLight
                      : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
                ),
              ),
              child: Icon(
                _selectedVideoFile != null ? Icons.video_file : Icons.video_library_outlined,
                size: 40,
                color: _selectedVideoFile != null 
                    ? AppTheme.primaryLight 
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _selectedVideoFile != null 
                  ? 'Video Selected'
                  : 'Tap to Select Video',
              style: AppTextStyles.h3.copyWith(
                color: _selectedVideoFile != null 
                    ? AppTheme.primaryLight 
                    : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            if (_selectedVideoFile != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _selectedVideoFile!.path.split('/').last,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ready to upload',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ] else ...[
              Text(
                'Choose a video file from your device',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                  ),
                ),
                child: Text(
                  'Supported: MP4, MOV, AVI',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
              ),
            ),
            child: TextButton(
              onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.secondaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _selectedVideoFile == null || _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Uploading...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.upload,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting video: $e')),
      );
    }
  }

  void _uploadVideo() async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Generate a title from the filename
      final fileName = _selectedVideoFile!.path.split('/').last;
      final videoTitle = fileName.replaceAll('.mp4', '').replaceAll('.mov', '').replaceAll('.avi', '');
      
      // Create video data with auto-generated title
      final videoData = {
        'title': videoTitle,
        'videoUrl': 'placeholder_video_url', // This would be the uploaded video URL
        'thumbnailUrl': 'placeholder_thumbnail_url', // This would be the video thumbnail
        'duration': 0, // This will be calculated using FFmpeg
        'fileSize': _selectedVideoFile!.lengthSync(),
        'order': 1, // This would be calculated based on existing videos
        'status': 'processing',
      };

      if (widget.moduleId != null) {
        context.read<CourseBloc>().add(CreateVideo(
          courseId: widget.courseId,
          moduleId: widget.moduleId!,
          videoData: videoData,
          videoFile: _selectedVideoFile!.path,
        ));
      } else {
        // If no module ID, we need to create the module first
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please save the module first before uploading videos'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
        return;
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _selectedVideoFile = null;
    _isUploading = false;
    super.dispose();
  }
}
