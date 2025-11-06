import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';

/// Video player widget that supports both Cloudinary HLS streaming and regular video URLs
/// Uses the standard video_player package which natively supports HLS (.m3u8)
class CloudinaryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? streamingUrl; // HLS streaming URL (optional)
  final Map<String, String>? qualities; // Quality-specific URLs
  final String? thumbnailUrl;
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

  const CloudinaryVideoPlayer({
    super.key,
    required this.videoUrl,
    this.streamingUrl,
    this.qualities,
    this.thumbnailUrl,
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
  State<CloudinaryVideoPlayer> createState() => _CloudinaryVideoPlayerState();
}

class _CloudinaryVideoPlayerState extends State<CloudinaryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _controlsTimer;
  DateTime? _lastProgressUpdateTime;
  double _lastReportedPercentage = 0.0;
  bool _videoEndedReported = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(CloudinaryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.streamingUrl != widget.streamingUrl) {
      print('CloudinaryVideoPlayer: Video URL changed, reinitializing...');
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
      _controller = null;

      setState(() {
        _isInitialized = false;
        _isPlaying = false;
        _showControls = false;
        _hasError = false;
        _errorMessage = null;
        _duration = Duration.zero;
        _position = Duration.zero;
        _lastProgressUpdateTime = null;
        _lastReportedPercentage = 0.0;
        _videoEndedReported = false;
      });

      if (!widget.isPremium) {
        _initializePlayer();
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      // Use streaming URL if available, otherwise use regular video URL
      // video_player natively supports HLS (.m3u8) streams
      final videoUrlToUse = widget.streamingUrl ?? widget.videoUrl;
      final isHlsStream = videoUrlToUse.endsWith('.m3u8');

      print('CloudinaryVideoPlayer: Initializing player');
      print('CloudinaryVideoPlayer: URL: $videoUrlToUse');
      print('CloudinaryVideoPlayer: Is HLS: $isHlsStream');
      print('CloudinaryVideoPlayer: Has qualities: ${widget.qualities != null}');

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrlToUse));
      await _controller!.initialize();

      if (mounted) {
        print('CloudinaryVideoPlayer: Video initialized successfully');
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
          _duration = _controller!.value.duration;
        });

        _controller!.addListener(_videoListener);

        // Auto-play the video
        print('CloudinaryVideoPlayer: Auto-playing video...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _controller != null) {
            _controller!.play();
            setState(() {
              _isPlaying = true;
              _showControls = false;
            });
            _startControlsTimer();
            print('CloudinaryVideoPlayer: Video auto-play started');
          }
        });
      }
    } catch (e) {
      print('CloudinaryVideoPlayer: Error initializing player: $e');
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
      _handleProgressUpdate();

      // Call onVideoEnded when video completes
      if (!wasCompleted && isCompleted && !_videoEndedReported) {
        _handleVideoEnded();
      }
    }
  }

  void _handleProgressUpdate() {
    if (widget.onProgressUpdate == null || _controller == null) return;

    if (_duration.inSeconds == 0) return;

    final watchPercentage = (_position.inSeconds / _duration.inSeconds) * 100;
    final now = DateTime.now();

    // Throttle progress updates to once every 3 seconds
    // OR if percentage change is significant (> 2%)
    // OR if video is near completion (>= 95%)
    final shouldUpdate = _lastProgressUpdateTime == null ||
        now.difference(_lastProgressUpdateTime!).inSeconds >= 3 ||
        (watchPercentage - _lastReportedPercentage).abs() >= 2.0 ||
        (watchPercentage >= 95.0 && _lastReportedPercentage < 95.0);

    if (shouldUpdate) {
      _lastProgressUpdateTime = now;
      _lastReportedPercentage = watchPercentage;
      widget.onProgressUpdate!(watchPercentage, _position);
    }
  }

  void _handleVideoEnded() {
    if (!_videoEndedReported && widget.onVideoEnded != null) {
      print('CloudinaryVideoPlayer: Video ended');
      _videoEndedReported = true;
      widget.onVideoEnded!();
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
          _showControls = true;
          _controlsTimer?.cancel();
        } else {
          _controller!.play();
          _showControls = false;
          _startControlsTimer();
        }
      });
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
    print('=== CLOUDINARY VIDEO PLAYER DEBUG ===');
    print('Video URL: ${widget.videoUrl}');
    print('Streaming URL: ${widget.streamingUrl}');
    print('Video Title: ${widget.videoTitle}');
    print('Is Premium: ${widget.isPremium}');
    print('Has Qualities: ${widget.qualities != null}');
    print('Thumbnail URL: ${widget.thumbnailUrl}');
    print('Controller Initialized: $_isInitialized');
    print('Has Error: $_hasError');
    print('=====================================');
    print('');

    if (widget.isPremium) {
      return _buildPremiumLockedPlayer();
    }

    if (_hasError) {
      return _buildErrorPlayer();
    }

    if (!_isInitialized || _controller == null) {
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
                color: AppTheme.primaryLight,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to load video',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        if (_isPlaying) {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _startControlsTimer();
          } else {
            _controlsTimer?.cancel();
          }
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

              // Navigation buttons
              _buildNavigationButtons(),

              // Bottom controls
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
                    playedColor: AppTheme.primaryLight,
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

                    // HLS indicator badge
                    if (widget.streamingUrl != null && widget.streamingUrl!.endsWith('.m3u8'))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HLS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (widget.streamingUrl != null && widget.streamingUrl!.endsWith('.m3u8'))
                      const SizedBox(width: 8),
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
                  print('CloudinaryVideoPlayer: Previous video button tapped');
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
                  print('CloudinaryVideoPlayer: Next video button tapped');
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
