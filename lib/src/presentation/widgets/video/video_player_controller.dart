import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../data/models/video_playlist_model.dart';
import 'cloudinary_video_player.dart';

/// Video Player Controller
/// Manages video playback with playlist support
/// Handles navigation, progress tracking, and auto-play

class VideoPlayerController extends StatefulWidget {
  final VideoPlaylist playlist;
  final String? initialVideoId; // Optional: start with specific video
  final VoidCallback? onPlaylistEnd; // Called when playlist ends
  final bool autoPlayNext; // Auto-play next video when current ends
  final Function(String videoId)? onVideoChanged; // Called when video changes

  const VideoPlayerController({
    super.key,
    required this.playlist,
    this.initialVideoId,
    this.onPlaylistEnd,
    this.autoPlayNext = true,
    this.onVideoChanged,
  });

  @override
  State<VideoPlayerController> createState() => _VideoPlayerControllerState();
}

class _VideoPlayerControllerState extends State<VideoPlayerController> {
  late VideoPlaylist _playlist;
  VideoPlaylistItem? _currentVideo;
  bool _isInitialized = false;

  // Progress tracking state
  double _lastUpdatePercentage = 0.0;
  bool _videoCompletedFlag = false;
  String? _lastVideoId;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _initializePlaylist();
  }

  @override
  void didUpdateWidget(VideoPlayerController oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If playlist changed, reinitialize
    if (oldWidget.playlist != widget.playlist) {
      _playlist = widget.playlist;
      _initializePlaylist();
    }
  }

  void _initializePlaylist() {
    print('VideoPlayerController: Initializing playlist');
    _playlist.printPlaylistInfo();

    // Set initial video
    if (widget.initialVideoId != null) {
      // Try to set specific video
      final success = _playlist.setCurrentVideoById(widget.initialVideoId!);
      if (success) {
        _currentVideo = _playlist.currentVideo;
        print('VideoPlayerController: Set initial video to ${_currentVideo?.videoTitle}');
      } else {
        // Fallback to first accessible
        _currentVideo = _playlist.getFirstAccessibleVideo();
        print('VideoPlayerController: Initial video ID not found, using first accessible');
      }
    } else {
      // Start with first accessible video
      _currentVideo = _playlist.getFirstAccessibleVideo();
      print('VideoPlayerController: Using first accessible video');
    }

    setState(() {
      _isInitialized = true;
      _resetProgressTracking();
    });

    if (_currentVideo == null) {
      print('VideoPlayerController: WARNING - No accessible videos found!');
    }
  }

  void _resetProgressTracking() {
    _lastUpdatePercentage = 0.0;
    _videoCompletedFlag = false;
    _lastVideoId = _currentVideo?.videoId;
    _lastUpdateTime = null;
    print('VideoPlayerController: Reset progress tracking for video: ${_currentVideo?.videoId}');
  }

  void _onProgressUpdate(double watchPercentage, Duration watchedDuration) {
    if (_currentVideo == null) return;

    // Check if video changed unexpectedly
    if (_lastVideoId != _currentVideo!.videoId) {
      print('VideoPlayerController: Video changed, resetting progress tracking');
      _resetProgressTracking();
    }

    final isFinalUpdate = watchPercentage >= 100.0;

    // Skip if already completed (unless it's the final 100% update)
    if (_videoCompletedFlag && !isFinalUpdate) {
      return;
    }

    // Prevent backward progress for near-complete videos
    if (watchPercentage < _lastUpdatePercentage && _lastUpdatePercentage >= 85.0 && !isFinalUpdate) {
      print('VideoPlayerController: Preventing backward progress ($_lastUpdatePercentage% -> $watchPercentage%)');
      return;
    }

    // Debounce rapid updates (minimum 2 seconds), but always allow 100%
    final now = DateTime.now();
    if (_lastUpdateTime != null && watchPercentage < 95.0 && !isFinalUpdate) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate.inSeconds < 2) {
        return;
      }
    }

    // Only update if significant change OR near completion OR final
    final isSignificantChange = (watchPercentage - _lastUpdatePercentage).abs() >= 5.0;
    final isNearComplete = watchPercentage >= 95.0;

    if (isSignificantChange || isNearComplete || isFinalUpdate) {
      _lastUpdatePercentage = watchPercentage;
      _lastUpdateTime = now;

      // Mark as completed only when reaching 100%
      if (watchPercentage >= 100.0) {
        _videoCompletedFlag = true;
        print('VideoPlayerController: Video marked as 100% complete');
      }

      // Send progress update to BLoC
      print('VideoPlayerController: Sending progress update - $watchPercentage% for video ${_currentVideo!.videoId}');
      context.read<UserProgressBloc>().add(UpdateVideoProgress(
        courseId: _currentVideo!.courseId,
        moduleId: _currentVideo!.moduleId,
        videoId: _currentVideo!.videoId,
        watchPercentage: watchPercentage,
        watchedDuration: watchedDuration,
      ));
    }
  }

  void _onVideoEnded() {
    print('VideoPlayerController: Video ended');

    // Check if there's a next video
    if (_playlist.hasNext) {
      if (widget.autoPlayNext) {
        print('VideoPlayerController: Auto-playing next video in 2 seconds...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _playNext();
          }
        });
      } else {
        print('VideoPlayerController: Auto-play disabled, stopped at current video');
      }
    } else {
      // Last video completed - trigger playlist end callback
      print('VideoPlayerController: Last video completed, playlist ended');
      if (widget.onPlaylistEnd != null) {
        // Delay slightly so user sees video completion
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onPlaylistEnd!();
          }
        });
      }
    }
  }

  void _playNext() {
    final nextVideo = _playlist.getNext();
    if (nextVideo != null) {
      print('VideoPlayerController: Playing next video - ${nextVideo.videoTitle}');
      setState(() {
        _currentVideo = nextVideo;
        _resetProgressTracking();
      });

      // Notify parent about video change
      if (widget.onVideoChanged != null) {
        widget.onVideoChanged!(nextVideo.videoId);
      }
    } else {
      print('VideoPlayerController: No next video available');
      _showMessage('No more videos available');
    }
  }

  void _playPrevious() {
    final previousVideo = _playlist.getPrevious();
    if (previousVideo != null) {
      print('VideoPlayerController: Playing previous video - ${previousVideo.videoTitle}');
      setState(() {
        _currentVideo = previousVideo;
        _resetProgressTracking();
      });

      // Notify parent about video change
      if (widget.onVideoChanged != null) {
        widget.onVideoChanged!(previousVideo.videoId);
      }
    } else {
      print('VideoPlayerController: No previous video available');
      _showMessage('Already at first video');
    }
  }

  Future<Map<String, dynamic>?> _getNextVideoData() async {
    final nextVideo = _playlist.peekNext();
    if (nextVideo != null) {
      return nextVideo.rawData;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getPreviousVideoData() async {
    final previousVideo = _playlist.peekPrevious();
    if (previousVideo != null) {
      return previousVideo.rawData;
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoading();
    }

    if (_currentVideo == null) {
      return _buildNoVideos();
    }

    return _buildVideoPlayer();
  }

  Widget _buildLoading() {
    return Container(
      height: 250,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildNoVideos() {
    // Debug: Log why no videos are available
    print('\n========== NO VIDEOS AVAILABLE ==========');
    print('Has Course Access: ${widget.playlist.hasCourseAccess}');
    print('Total videos in playlist: ${widget.playlist.length}');
    print('Accessible videos: ${widget.playlist.getAccessibleVideos().length}');
    if (widget.playlist.isNotEmpty) {
      print('\nPlaylist items:');
      for (int i = 0; i < widget.playlist.items.length; i++) {
        final item = widget.playlist.items[i];
        print('  [$i] ${item.videoTitle}');
        print('      - isPremium: ${item.isPremium}');
        print('      - hasAccess: ${widget.playlist.hasCourseAccess || !item.isPremium}');
      }
    }
    print('=========================================\n');

    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              widget.playlist.hasCourseAccess
                  ? 'No videos available'
                  : 'Purchase course to access videos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Header with module info
        _buildVideoHeader(),

        // Video Player
        CloudinaryVideoPlayer(
          key: ValueKey(_currentVideo!.videoId), // Force rebuild on video change
          videoUrl: _currentVideo!.videoUrl,
          streamingUrl: _currentVideo!.rawData['streamingUrl'], // Cloudinary HLS streaming
          qualities: _currentVideo!.rawData['qualities'] != null
              ? Map<String, String>.from(_currentVideo!.rawData['qualities'])
              : null,
          thumbnailUrl: _currentVideo!.rawData['thumbnailUrl'],
          videoTitle: _currentVideo!.videoTitle,
          isPremium: false, // Already filtered by playlist
          courseId: _currentVideo!.courseId,
          moduleId: _currentVideo!.moduleId,
          videoId: _currentVideo!.videoId,
          duration: _currentVideo!.duration,
          onProgressUpdate: _onProgressUpdate,
          onVideoEnded: _onVideoEnded,
          onNextVideo: _playlist.hasNext ? _playNext : null,
          onPreviousVideo: _playlist.hasPrevious ? _playPrevious : null,
          hasNextVideo: _playlist.hasNext,
          hasPreviousVideo: _playlist.hasPrevious,
        ),
      ],
    );
  }

  Widget _buildVideoHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Module badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryLight.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: AppTheme.primaryLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentVideo!.moduleName.length > 20
                      ? '${_currentVideo!.moduleName.substring(0, 20)}...'
                      : _currentVideo!.moduleName,
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Position indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _playlist.getCurrentPositionText(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Video title
          Expanded(
            child: Text(
              _currentVideo!.videoTitle,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
