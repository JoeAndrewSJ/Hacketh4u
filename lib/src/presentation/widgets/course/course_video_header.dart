import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../widgets/video/video_player_widget.dart';

class CourseVideoHeader extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final Map<String, dynamic>? selectedVideo;
  final VoidCallback? onVideoTap;
  final bool hasCourseAccess;
  final List<Map<String, dynamic>> modules;
  final Function(Map<String, dynamic>)? onNextVideo;

  const CourseVideoHeader({
    super.key,
    required this.course,
    required this.isDark,
    this.selectedVideo,
    this.onVideoTap,
    this.hasCourseAccess = false,
    this.modules = const [],
    this.onNextVideo,
  });

  @override
  State<CourseVideoHeader> createState() => _CourseVideoHeaderState();
}

class _CourseVideoHeaderState extends State<CourseVideoHeader> {
  double _lastUpdatePercentage = 0.0;

  void _onProgressUpdate(double watchPercentage, Duration watchedDuration) {
    // Only update every 5% to avoid too many database calls
    if ((watchPercentage - _lastUpdatePercentage).abs() >= 5.0 || watchPercentage >= 100.0) {
      _lastUpdatePercentage = watchPercentage;
      
      if (widget.hasCourseAccess && widget.selectedVideo != null) {
        context.read<UserProgressBloc>().add(UpdateVideoProgress(
          courseId: widget.course['id'],
          moduleId: widget.selectedVideo!['moduleId'] ?? '',
          videoId: widget.selectedVideo!['id'] ?? '',
          watchPercentage: watchPercentage,
          watchedDuration: watchedDuration,
        ));
      }
    }
  }

  void _onVideoEnded() {
    print('CourseVideoHeader: Video ended, looking for next video...');
    print('CourseVideoHeader: hasCourseAccess: ${widget.hasCourseAccess}, onNextVideo: ${widget.onNextVideo != null}');
    print('CourseVideoHeader: Current video: ${widget.selectedVideo?['title']}');
    print('CourseVideoHeader: Total modules: ${widget.modules.length}');
    
    if (widget.hasCourseAccess && widget.onNextVideo != null) {
      // Wait 2 seconds before auto-playing next video
      print('CourseVideoHeader: Starting 2-second delay before auto-play...');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('CourseVideoHeader: 2-second delay completed, finding next video...');
          _findAndPlayNextVideo();
        } else {
          print('CourseVideoHeader: Widget not mounted, skipping auto-play');
        }
      });
    } else {
      print('CourseVideoHeader: Cannot auto-play - hasCourseAccess: ${widget.hasCourseAccess}, onNextVideo callback: ${widget.onNextVideo != null}');
    }
  }

  void _findAndPlayNextVideo() {
    if (widget.selectedVideo == null || widget.modules.isEmpty) return;

    final currentVideoId = widget.selectedVideo!['id'];
    final currentModuleId = widget.selectedVideo!['moduleId'];

    // Find current video index in current module
    final currentModule = widget.modules.firstWhere(
      (module) => module['id'] == currentModuleId,
      orElse: () => <String, dynamic>{},
    );

    if (currentModule.isEmpty) return;

    final videos = currentModule['videos'] as List<dynamic>? ?? [];
    final currentVideoIndex = videos.indexWhere(
      (video) => video['id'] == currentVideoId,
    );

    if (currentVideoIndex == -1) return;

    // Check if there's a next video in current module
    if (currentVideoIndex + 1 < videos.length) {
      final nextVideo = videos[currentVideoIndex + 1];
      final nextVideoMap = Map<String, dynamic>.from(nextVideo as Map);
      final isPremium = nextVideoMap['isPremium'] ?? false;
      final hasAccess = !isPremium || widget.hasCourseAccess;

      if (hasAccess) {
        print('CourseVideoHeader: Auto-playing next video in same module: ${nextVideoMap['title']}');
        widget.onNextVideo!(nextVideoMap);
        return;
      } else {
        print('CourseVideoHeader: Next video in same module is not accessible, looking in next modules...');
      }
    } else {
      print('CourseVideoHeader: No more videos in current module, looking in next modules...');
    }

    // Look for next video in next module
    final currentModuleIndex = widget.modules.indexWhere(
      (module) => module['id'] == currentModuleId,
    );

    print('CourseVideoHeader: Current module index: $currentModuleIndex, Total modules: ${widget.modules.length}');

    if (currentModuleIndex == -1) {
      print('CourseVideoHeader: Current module not found');
      return;
    }

    if (currentModuleIndex + 1 >= widget.modules.length) {
      print('CourseVideoHeader: No more modules to auto-play');
      return;
    }

    // Check next modules for accessible videos (start from the very next module)
    for (int i = currentModuleIndex + 1; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      final isModulePremium = module['isPremium'] ?? (module['type'] == 'premium');
      final hasModuleAccess = !isModulePremium || widget.hasCourseAccess;

      print('CourseVideoHeader: Checking module $i: ${module['title']}, isPremium: $isModulePremium, hasModuleAccess: $hasModuleAccess');

      if (hasModuleAccess) {
        final moduleVideos = module['videos'] as List<dynamic>? ?? [];
        print('CourseVideoHeader: Module has ${moduleVideos.length} videos');
        
        for (final video in moduleVideos) {
          final videoMap = Map<String, dynamic>.from(video as Map);
          final isVideoPremium = videoMap['isPremium'] ?? false;
          final hasVideoAccess = !isVideoPremium || widget.hasCourseAccess;

          print('CourseVideoHeader: Checking video: ${videoMap['title']}, isPremium: $isVideoPremium, hasAccess: $hasVideoAccess');

          if (hasVideoAccess) {
            print('CourseVideoHeader: Auto-playing first accessible video in next module: ${videoMap['title']}');
            widget.onNextVideo!(videoMap);
            return;
          }
        }
      } else {
        print('CourseVideoHeader: Module ${module['title']} is not accessible (premium)');
      }
    }

    print('CourseVideoHeader: No more accessible videos to auto-play');
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      floating: true,
      backgroundColor: widget.isDark ? AppTheme.surfaceDark : Colors.white,
      foregroundColor: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
      title: widget.selectedVideo != null 
          ? Text(
              widget.selectedVideo!['title'] ?? 'Video',
              style: TextStyle(
                color: widget.isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player or Thumbnail
              _buildVideoContent(),
              // Gradient Overlay
              _buildGradientOverlay(),
              // Course Title Overlay
              _buildTitleOverlay(),
              // Play Button Overlay (when not playing video)
              _buildPlayButtonOverlay(),
            ],
          ),
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
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20,
          ),
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
            child: const Icon(
              Icons.share,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    // If we have a selected video and it's free, show video player
    if (widget.selectedVideo != null) {
      final isPremium = widget.selectedVideo!['isPremium'] ?? false;
      if (!isPremium) {
        return _buildFullScreenVideoPlayer();
      }
    }

    // Otherwise show thumbnail
    return _buildThumbnail();
  }

  Widget _buildFullScreenVideoPlayer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video player fills entire space
          Center(
            child: VideoPlayerWidget(
              videoUrl: widget.selectedVideo!['videoUrl'] ?? '',
              videoTitle: widget.selectedVideo!['title'] ?? 'Video',
              isPremium: false,
              courseId: widget.hasCourseAccess ? widget.course['id'] : null,
              moduleId: widget.hasCourseAccess ? widget.selectedVideo!['moduleId'] : null,
              videoId: widget.hasCourseAccess ? widget.selectedVideo!['id'] : null,
              duration: widget.selectedVideo!['duration'] ?? 0,
              onProgressUpdate: widget.hasCourseAccess ? _onProgressUpdate : null,
              onVideoEnded: widget.hasCourseAccess ? _onVideoEnded : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbnailUrl = widget.course['thumbnailUrl'] ?? '';
    
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
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleOverlay() {
    // Only show course title and info when no video is selected
    if (widget.selectedVideo == null) {
      return Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: IgnorePointer(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course['title'] ?? 'Course Title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(widget.course['totalDuration'] ?? 0),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.course['studentCount'] ?? 0} students',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      );
    }

    // No overlay when video is playing - title is shown in the app bar
    return const SizedBox.shrink();
  }

  Widget _buildPlayButtonOverlay() {
    // Only show play button if no video is selected
    if (widget.selectedVideo != null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          if (widget.onVideoTap != null) {
            widget.onVideoTap!();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

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
