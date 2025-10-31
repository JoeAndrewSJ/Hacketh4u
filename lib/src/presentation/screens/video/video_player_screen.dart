import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../../../core/bloc/user_progress/user_progress_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String videoId;
  final String videoTitle;
  final String videoUrl;
  final int duration;
  final bool isDark;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.videoId,
    required this.videoTitle,
    required this.videoUrl,
    required this.duration,
    required this.isDark,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _hasCourseAccess = false;
  bool _isCheckingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkCourseAccess();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _checkCourseAccess() {
    // Check if user has access to this course
    context.read<CourseAccessBloc>().add(CheckCourseAccess(courseId: widget.courseId));
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
          _duration = Duration(seconds: widget.duration);
        });

        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      final isPlaying = _controller!.value.isPlaying;
      final position = _controller!.value.position;

      setState(() {
        _position = position;
        _isPlaying = isPlaying;

        if (!isPlaying && position >= _duration && _duration > Duration.zero) {
          _showControls = true;
          // Video completed
          _onVideoCompleted();
        }
      });

      // Update progress tracking
      if (_hasCourseAccess && isPlaying) {
        _updateProgress(position);
      }
    }
  }

  void _updateProgress(Duration position) {
    // Calculate watch percentage
    final watchPercentage = (_duration.inSeconds > 0) 
        ? (position.inSeconds / _duration.inSeconds) * 100 
        : 0.0;

    // Update progress every 5% or when video ends
    if (watchPercentage % 5 == 0 || position >= _duration) {
      context.read<UserProgressBloc>().add(UpdateVideoProgress(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        videoId: widget.videoId,
        watchPercentage: watchPercentage,
        watchedDuration: position,
      ));
    }
  }

  void _onVideoCompleted() {
    if (_hasCourseAccess) {
      // Mark video as completed (100%)
      context.read<UserProgressBloc>().add(UpdateVideoProgress(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        videoId: widget.videoId,
        watchPercentage: 100.0,
        watchedDuration: _duration,
      ));
    }
  }

  void _togglePlayPause() {
    if (_controller != null) {
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
          _showControls = true;
        } else {
          _controller!.play();
          _showControls = false;
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.videoTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<CourseAccessBloc, CourseAccessState>(
        listener: (context, state) {
          if (state is CourseAccessChecked) {
            setState(() {
              _hasCourseAccess = state.hasAccess;
              _isCheckingAccess = false;
            });
          }
        },
        child: _isCheckingAccess
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _hasCourseAccess
                ? _buildVideoPlayer()
                : _buildAccessDenied(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorPlayer();
    }

    if (!_isInitialized) {
      return _buildLoadingPlayer();
    }

    return GestureDetector(
        onTap: () {
          if (_isPlaying) {
            setState(() {
              _showControls = !_showControls;
            });
          } else {
            _togglePlayPause();
          }
        },
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width * 9 / 16, // 16:9 aspect ratio
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),

                if (!_isPlaying) _buildCenterPlayButton(),

                if (_showControls || !_isPlaying) _buildControls(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: const Icon(Icons.lock, color: Colors.amber, size: 60),
          ),
          const SizedBox(height: 24),
          const Text(
            'Premium Content',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This video is only available for purchased courses',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlayer() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width * 9 / 16,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlayer() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width * 9 / 16,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Unable to load video',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    bufferedColor: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Text('/', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),

                    GestureDetector(
                      onTap: _togglePlayPause,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
