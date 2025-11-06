import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';

class VideoProgressTracker extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String videoId;
  final String videoTitle;
  final Duration totalDuration;
  final bool isDark;
  final Widget child; // The video player widget

  const VideoProgressTracker({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.videoId,
    required this.videoTitle,
    required this.totalDuration,
    required this.isDark,
    required this.child,
  });

  @override
  State<VideoProgressTracker> createState() => _VideoProgressTrackerState();
}

class _VideoProgressTrackerState extends State<VideoProgressTracker> {
  Duration _currentPosition = Duration.zero;
  double _watchPercentage = 0.0;
  bool _isTracking = false;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadVideoProgress();
  }

  void _loadVideoProgress() {
    // Load user progress to get current video progress
    context.read<UserProgressBloc>().add(LoadUserProgress(courseId: widget.courseId));
  }

  void _updateVideoProgress() {
    if (!_isTracking || widget.totalDuration.inSeconds == 0) return;

    final currentPercentage = (_currentPosition.inSeconds / widget.totalDuration.inSeconds) * 100;

    // Dynamic threshold: 2% for videos, or every 3 seconds, whichever is smaller
    const percentageThreshold = 2.0;
    const timeThreshold = 3; // seconds
    final timeDiff = _lastUpdateTime != null
        ? DateTime.now().difference(_lastUpdateTime!).inSeconds
        : timeThreshold + 1;

    // Update if percentage changed significantly OR enough time passed
    final shouldUpdate = (currentPercentage - _watchPercentage).abs() >= percentageThreshold ||
                        timeDiff >= timeThreshold;

    if (shouldUpdate) {
      setState(() {
        _watchPercentage = currentPercentage;
      });

      // Update progress in the repository
      context.read<UserProgressBloc>().add(UpdateVideoProgress(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        videoId: widget.videoId,
        watchPercentage: currentPercentage,
        watchedDuration: _currentPosition,
      ));

      _lastUpdateTime = DateTime.now();
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });

    // Final update when stopping - use current _watchPercentage instead of recalculating
    if (widget.totalDuration.inSeconds > 0) {
      context.read<UserProgressBloc>().add(UpdateVideoProgress(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        videoId: widget.videoId,
        watchPercentage: _watchPercentage,
        watchedDuration: _currentPosition,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserProgressBloc, UserProgressState>(
      listener: (context, state) {
        if (state is UserProgressLoaded) {
          // Find the current video progress
          final moduleProgress = state.userProgress.moduleProgresses[widget.moduleId];
          if (moduleProgress != null) {
            final videoProgress = moduleProgress.videoProgresses[widget.videoId];
            if (videoProgress != null) {
              setState(() {
                _watchPercentage = videoProgress.watchPercentage;
                _currentPosition = videoProgress.watchedDuration;
              });
            }
          }
        }
      },
      child: Stack(
        children: [
          // The video player widget
          widget.child,
          
          // Progress tracking overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProgressOverlay(),
          ),
          
          // Play/Pause tracking controls
          Positioned(
            top: 8,
            right: 8,
            child: _buildTrackingControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Container(
      padding: const EdgeInsets.all(8),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _watchPercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          
          // Progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDuration(_currentPosition)} / ${_formatDuration(widget.totalDuration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_watchPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _watchPercentage >= 90 ? Colors.green : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isTracking ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_isTracking) {
                _stopTracking();
              } else {
                _startTracking();
              }
            },
            tooltip: _isTracking ? 'Pause tracking' : 'Start tracking',
          ),
          const SizedBox(width: 4),
          Text(
            _isTracking ? 'Tracking' : 'Paused',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Public methods to update video position from external video player
  void updatePosition(Duration position) {
    setState(() {
      _currentPosition = position;
    });
    _updateVideoProgress();
  }

  void onVideoStarted() {
    _startTracking();
  }

  void onVideoPaused() {
    _stopTracking();
  }

  void onVideoEnded() {
    setState(() {
      _currentPosition = widget.totalDuration;
      _watchPercentage = 100.0;
      _isTracking = false;
    });

    // Send final update with 100% completion
    context.read<UserProgressBloc>().add(UpdateVideoProgress(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      videoId: widget.videoId,
      watchPercentage: 100.0,
      watchedDuration: widget.totalDuration,
    ));
  }
}

// Mixin for video players to easily integrate with progress tracking
mixin VideoProgressMixin {
  late VideoProgressTracker? _progressTracker;

  void attachProgressTracker(VideoProgressTracker tracker) {
    _progressTracker = tracker;
  }

  void updateProgress(Duration position) {
    // Progress tracking functionality removed for compatibility
  }

  void onVideoPlay() {
    // Video play tracking functionality removed for compatibility
  }

  void onVideoPause() {
    // Video pause tracking functionality removed for compatibility
  }

  void onVideoComplete() {
    // Video complete tracking functionality removed for compatibility
  }
}
