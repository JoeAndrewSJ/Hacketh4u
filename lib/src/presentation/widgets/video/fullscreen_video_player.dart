import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String initialVideoUrl;
  final String initialVideoTitle;
  final VoidCallback onExit;
  final Future<Map<String, dynamic>?> Function()? onGetNextVideo;
  final Future<Map<String, dynamic>?> Function()? onGetPreviousVideo;

  const FullscreenVideoPlayer({
    super.key,
    required this.initialVideoUrl,
    required this.initialVideoTitle,
    required this.onExit,
    this.onGetNextVideo,
    this.onGetPreviousVideo,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isLoadingNewVideo = false;
  Timer? _controlsTimer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _currentVideoTitle = '';
  String _currentVideoUrl = '';

  @override
  void initState() {
    super.initState();
    _currentVideoTitle = widget.initialVideoTitle;
    _currentVideoUrl = widget.initialVideoUrl;
    _initializeVideo(widget.initialVideoUrl);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      print('FullscreenVideoPlayer: ========================================');
      print('FullscreenVideoPlayer: Initializing video');
      print('FullscreenVideoPlayer: URL: $videoUrl');
      print('FullscreenVideoPlayer: Current URL: $_currentVideoUrl');

      // Dispose old controller if exists
      if (_controller != null) {
        print('FullscreenVideoPlayer: Disposing old controller');
        _controller!.removeListener(_listener);
        _controller!.dispose();
        _controller = null;
      }

      setState(() {
        _isInitialized = false;
        _hasError = false;
        _isLoadingNewVideo = true;
        _position = Duration.zero;
      });

      print('FullscreenVideoPlayer: Creating new controller');
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      print('FullscreenVideoPlayer: Initializing controller...');
      await _controller!.initialize();

      if (mounted) {
        print('FullscreenVideoPlayer: Controller initialized successfully');
        print('FullscreenVideoPlayer: Duration: ${_controller!.value.duration}');

        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isLoadingNewVideo = false;
          _duration = _controller!.value.duration;
        });

        _controller!.addListener(_listener);

        // Auto-play
        print('FullscreenVideoPlayer: Starting auto-play');
        await _controller!.play();

        setState(() {
          _isPlaying = true;
          _showControls = false;
        });
        _startControlsTimer();

        print('FullscreenVideoPlayer: Video playing successfully');
        print('FullscreenVideoPlayer: ========================================');
      }
    } catch (e) {
      print('FullscreenVideoPlayer: ❌ ERROR initializing video');
      print('FullscreenVideoPlayer: Error: $e');
      print('FullscreenVideoPlayer: ========================================');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingNewVideo = false;
        });
      }
    }
  }

  void _listener() {
    if (mounted && _controller != null) {
      final wasPlaying = _isPlaying;
      final nowPlaying = _controller!.value.isPlaying;
      final position = _controller!.value.position;

      setState(() {
        _position = position;

        if (wasPlaying != nowPlaying) {
          _isPlaying = nowPlaying;
          if (!_isPlaying) {
            _showControls = true;
            _controlsTimer?.cancel();
          } else {
            _startControlsTimer();
          }
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    if (_isPlaying) {
      _controller!.pause();
      setState(() {
        _showControls = true;
      });
      _controlsTimer?.cancel();
    } else {
      _controller!.play();
      setState(() {
        _showControls = false;
      });
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (_isPlaying) {
      setState(() {
        _showControls = !_showControls;
      });
      if (_showControls) {
        _startControlsTimer();
      } else {
        _controlsTimer?.cancel();
      }
    }
  }

  Future<void> _handleNextVideo() async {
    if (widget.onGetNextVideo == null) return;

    print('FullscreenVideoPlayer: Getting next video...');
    final nextVideo = await widget.onGetNextVideo!();

    if (nextVideo != null && mounted) {
      print('FullscreenVideoPlayer: Loading next video: ${nextVideo['title']}');
      setState(() {
        _currentVideoTitle = nextVideo['title'] ?? 'Video';
        _currentVideoUrl = nextVideo['videoUrl'] ?? '';
      });
      await _initializeVideo(nextVideo['videoUrl']);
    } else {
      print('FullscreenVideoPlayer: No next video available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('No more videos available')),
              ],
            ),
            backgroundColor: Colors.grey[850],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handlePreviousVideo() async {
    if (widget.onGetPreviousVideo == null) return;

    print('FullscreenVideoPlayer: Getting previous video...');
    final previousVideo = await widget.onGetPreviousVideo!();

    if (previousVideo != null && mounted) {
      print('FullscreenVideoPlayer: Loading previous video: ${previousVideo['title']}');
      setState(() {
        _currentVideoTitle = previousVideo['title'] ?? 'Video';
        _currentVideoUrl = previousVideo['videoUrl'] ?? '';
      });
      await _initializeVideo(previousVideo['videoUrl']);
    } else {
      print('FullscreenVideoPlayer: No previous video available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('No previous videos available')),
              ],
            ),
            backgroundColor: Colors.grey[850],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
      body: GestureDetector(
        onTap: () {
          if (_isPlaying && !_isLoadingNewVideo) {
            _toggleControls();
          } else if (!_isLoadingNewVideo) {
            _togglePlayPause();
          }
        },
        child: Stack(
          children: [
            // Video Player
            if (_isInitialized && !_hasError)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Loading Indicator
            if (_isLoadingNewVideo)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Error State
            if (_hasError && !_isLoadingNewVideo)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _initializeVideo(_currentVideoUrl),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Center Play Button
            if (!_isPlaying && _isInitialized && !_isLoadingNewVideo)
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

            // Navigation Buttons - ALWAYS visible when video is initialized
            if (_isInitialized && !_isLoadingNewVideo)
              _buildNavigationButtons(),

            // Controls - show/hide based on state
            if ((_showControls || !_isPlaying) && _isInitialized && !_isLoadingNewVideo)
              _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous Video Button
            if (widget.onGetPreviousVideo != null)
              GestureDetector(
                onTap: _handlePreviousVideo,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_previous_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

            const Spacer(),

            // Next Video Button
            if (widget.onGetNextVideo != null)
              GestureDetector(
                onTap: _handleNextVideo,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar
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
                    _currentVideoTitle,
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

          // Bottom Controls
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
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.blue,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white38,
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
    );
  }
}
