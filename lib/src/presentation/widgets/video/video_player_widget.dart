import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final bool isPremium;
  final VoidCallback? onLockedTap;
  final String? courseId;
  final String? moduleId;
  final String? videoId;
  final int? duration;
  final Function(double watchPercentage, Duration watchedDuration)? onProgressUpdate;
  final VoidCallback? onVideoEnded;
  final VoidCallback? onNextVideo;
  final VoidCallback? onPreviousVideo;
  final bool hasNextVideo;
  final bool hasPreviousVideo;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    this.isPremium = false,
    this.onLockedTap,
    this.courseId,
    this.moduleId,
    this.videoId,
    this.duration,
    this.onProgressUpdate,
    this.onVideoEnded,
    this.onNextVideo,
    this.onPreviousVideo,
    this.hasNextVideo = false,
    this.hasPreviousVideo = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _hasError = false;
  bool _isFullscreen = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the video URL has changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      print('VideoPlayerWidget: Video URL changed from "${oldWidget.videoUrl}" to "${widget.videoUrl}"');
      
      // Remove listener and dispose the old controller
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;
      
      // Reset state
      setState(() {
        _isInitialized = false;
        _isPlaying = false;
        _showControls = false;
        _hasError = false;
        _errorMessage = null;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
      
      // Initialize the new video if not premium
      if (!widget.isPremium) {
        print('VideoPlayerWidget: Initializing new video...');
        _initializeVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsTimer?.cancel();
    if (_isFullscreen) {
      _exitFullscreen();
    }
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      print('VideoPlayerWidget: Initializing video with URL: ${widget.videoUrl}');
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();

      if (mounted) {
        print('VideoPlayerWidget: Video initialized successfully');
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
          _duration = _controller!.value.duration;
        });

        _controller!.addListener(_videoListener);
        
        // Auto-play the video after initialization with a small delay
        print('VideoPlayerWidget: Auto-playing video...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _controller != null) {
            _controller!.play();
            setState(() {
              _isPlaying = true;
              _showControls = false;
            });
            _startControlsTimer(); // Start auto-hide timer for auto-play
            print('VideoPlayerWidget: Video auto-play started');
          }
        });
      }
    } catch (e) {
      print('VideoPlayerWidget: Error initializing video: $e');
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
      // Consider video completed when it reaches 98% or more of duration (to handle edge cases)
      final wasCompleted = _position.inSeconds >= (_duration.inSeconds * 0.98).round() && _duration > Duration.zero;
      final isCompleted = position.inSeconds >= (_duration.inSeconds * 0.98).round() && _duration > Duration.zero;

      setState(() {
        _position = position;
        _isPlaying = isPlaying;

        if (!isPlaying && isCompleted) {
          _showControls = true;
        }
      });

      // Update progress tracking
      if (widget.onProgressUpdate != null && _duration.inSeconds > 0) {
        final watchPercentage = (position.inSeconds / _duration.inSeconds) * 100;
        widget.onProgressUpdate!(watchPercentage, position);
      }

      // Call onVideoEnded when video completes (only once per completion)
      if (!wasCompleted && isCompleted && widget.onVideoEnded != null) {
        print('VideoPlayerWidget: Video completed!');
        print('VideoPlayerWidget: Position: ${position.inSeconds}s, Duration: ${_duration.inSeconds}s');
        print('VideoPlayerWidget: Completion threshold: ${(_duration.inSeconds * 0.98).round()}s');
        print('VideoPlayerWidget: Was completed: $wasCompleted, Is completed: $isCompleted');
        print('VideoPlayerWidget: Calling onVideoEnded callback...');
        widget.onVideoEnded!();
      }
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      print('VideoPlayerWidget: Toggling play/pause. Current state: $_isPlaying');
      
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
          _showControls = true;
          _controlsTimer?.cancel(); // Cancel auto-hide when paused
          print('VideoPlayerWidget: Video paused');
        } else {
          _controller!.play();
          _showControls = false;
          _startControlsTimer(); // Start auto-hide timer when playing
          print('VideoPlayerWidget: Video playing');
        }
      });
    } else {
      print('VideoPlayerWidget: Cannot toggle play/pause - controller: ${_controller != null}, initialized: $_isInitialized');
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
        print('VideoPlayerWidget: Auto-hiding controls');
      }
    });
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _FullscreenVideoPlayer(
            controller: _controller!,
            videoTitle: widget.videoTitle,
            onExit: _exitFullscreen,
          ),
        ),
      ).then((_) => _exitFullscreen());

      setState(() {
        _isFullscreen = true;
      });
    }
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (mounted) {
      setState(() {
        _isFullscreen = false;
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
    // Print video player structure for debugging
    print('=== VIDEO PLAYER WIDGET DEBUG ===');
    print('Video URL: ${widget.videoUrl}');
    print('Video Title: ${widget.videoTitle}');
    print('Is Premium: ${widget.isPremium}');
    print('Course ID: ${widget.courseId}');
    print('Module ID: ${widget.moduleId}');
    print('Video ID: ${widget.videoId}');
    print('Duration: ${widget.duration} seconds');
    print('Has Next Video: ${widget.hasNextVideo}');
    print('Has Previous Video: ${widget.hasPreviousVideo}');
    print('On Next Video Callback: ${widget.onNextVideo != null}');
    print('On Previous Video Callback: ${widget.onPreviousVideo != null}');
    print('On Progress Update Callback: ${widget.onProgressUpdate != null}');
    print('On Video Ended Callback: ${widget.onVideoEnded != null}');
    print('Controller Initialized: $_isInitialized');
    print('Is Playing: $_isPlaying');
    print('Has Error: $_hasError');
    print('Show Controls: $_showControls');
    print('================================');
    print('');
    
    if (widget.isPremium) {
      return _buildPremiumLockedPlayer();
    }

    if (_hasError) {
      return _buildErrorPlayer();
    }

    if (!_isInitialized) {
      return _buildLoadingPlayer();
    }

    return _buildVideoPlayer();
  }

  Widget _buildPremiumLockedPlayer() {
    return GestureDetector(
      onTap: widget.onLockedTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Center(
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
                    child: const Icon(Icons.lock, color: Colors.amber, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Premium Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upgrade and unlock',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlayer() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
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
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('Unable to load video',
                style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        print('VideoPlayerWidget: Main video area tapped. Current state: playing=$_isPlaying, showControls=$_showControls');
        if (_isPlaying) {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _startControlsTimer(); // Restart timer when showing controls
          } else {
            _controlsTimer?.cancel(); // Cancel timer when hiding controls
          }
          print('VideoPlayerWidget: Toggled controls visibility: $_showControls');
        } else {
          _togglePlayPause();
        }
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

              if (!_isPlaying) _buildCenterPlayButton(),

              // Navigation buttons overlay
              if (_showControls || !_isPlaying) _buildNavigationButtons(),

              if (_showControls || !_isPlaying) _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          print('VideoPlayerWidget: Center play button tapped');
          _togglePlayPause();
        },
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
                    // Play/Pause Button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Time Display
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Text('/', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),

                    // Fullscreen Button
                    GestureDetector(
                      onTap: _toggleFullscreen,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
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

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous Video Button
            if (widget.hasPreviousVideo && widget.onPreviousVideo != null)
              GestureDetector(
                onTap: () {
                  print('VideoPlayerWidget: Previous video button tapped');
                  widget.onPreviousVideo!();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            else if (!widget.hasPreviousVideo)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.skip_previous,
                  color: Colors.white.withOpacity(0.3),
                  size: 24,
                ),
              ),

            const Spacer(),

            // Next Video Button
            if (widget.hasNextVideo && widget.onNextVideo != null)
              GestureDetector(
                onTap: () {
                  print('VideoPlayerWidget: Next video button tapped');
                  widget.onNextVideo!();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            else if (!widget.hasNextVideo)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.skip_next,
                  color: Colors.white.withOpacity(0.3),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoTitle;
  final VoidCallback onExit;

  const _FullscreenVideoPlayer({
    required this.controller,
    required this.videoTitle,
    required this.onExit,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _showControls = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller.value.isPlaying;
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
        if (!_isPlaying) {
          _showControls = true;
        }
      });
    }
  }

  void _togglePlayPause() {
    print('FullscreenVideoPlayer: Toggling play/pause. Current state: $_isPlaying');
    setState(() {
      if (_isPlaying) {
        widget.controller.pause();
        print('FullscreenVideoPlayer: Video paused');
      } else {
        widget.controller.play();
        print('FullscreenVideoPlayer: Video playing');
      }
    });
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
      body: GestureDetector(
        onTap: () {
          if (_isPlaying) {
            setState(() {
              _showControls = !_showControls;
            });
          } else {
            _togglePlayPause();
          }
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            if (!_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),

            if (_showControls || !_isPlaying)
              SafeArea(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              widget.onExit();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              widget.videoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            VideoProgressIndicator(
                              widget.controller,
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
                                // Play/Pause Button
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
                                const SizedBox(width: 8),

                                // Time Display
                                Text(
                                  _formatDuration(widget.controller.value.position),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Text('/', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(widget.controller.value.duration),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const Spacer(),

                                // Exit Fullscreen Button
                                GestureDetector(
                                  onTap: () {
                                    widget.onExit();
                                    Navigator.of(context).pop();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_exit,
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
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}