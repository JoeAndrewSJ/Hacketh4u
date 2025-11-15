import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/user_progress/user_progress_bloc.dart';
import '../../../core/bloc/user_progress/user_progress_event.dart';
import '../video/cloudinary_video_player.dart';

class CourseVideoHeader extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final Map<String, dynamic>? selectedVideo;
  final VoidCallback? onVideoTap;
  final bool hasCourseAccess;
  final List<Map<String, dynamic>> modules;
  final Function(Map<String, dynamic>)? onNextVideo;
  final Function(Map<String, dynamic>)? onPreviousVideo;

  const CourseVideoHeader({
    super.key,
    required this.course,
    required this.isDark,
    this.selectedVideo,
    this.onVideoTap,
    this.hasCourseAccess = false,
    this.modules = const [],
    this.onNextVideo,
    this.onPreviousVideo,
  });

  @override
  State<CourseVideoHeader> createState() => _CourseVideoHeaderState();
}

class _CourseVideoHeaderState extends State<CourseVideoHeader> {
  double _lastUpdatePercentage = 0.0;
  bool _videoCompletedFlag = false; // Track if 100% update was sent
  String? _lastVideoId; // Track which video we're watching
  DateTime? _lastUpdateTime; // Track when last update was sent

  @override
  void didUpdateWidget(CourseVideoHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset completion flag when video changes
    if (oldWidget.selectedVideo?['id'] != widget.selectedVideo?['id']) {
      _videoCompletedFlag = false;
      _lastUpdatePercentage = 0.0;
      _lastVideoId = widget.selectedVideo?['id'];
      _lastUpdateTime = null;
    }
  }

  void _onProgressUpdate(double watchPercentage, Duration watchedDuration) {
    // EDGE CASE 1: Allow 100% updates to bypass completion flag (for final progress)
    final isFinalUpdate = watchPercentage >= 100.0;

    if (_videoCompletedFlag && !isFinalUpdate) {
      print('CourseVideoHeader: Video already marked complete, skipping non-final update');
      return;
    }

    // EDGE CASE 2: Prevent backward progress for near-complete videos (unless it's 100%)
    if (watchPercentage < _lastUpdatePercentage && _lastUpdatePercentage >= 85.0 && !isFinalUpdate) {
      print('CourseVideoHeader: Preventing backward progress ($_lastUpdatePercentage% -> $watchPercentage%)');
      return;
    }

    // EDGE CASE 3: Debounce rapid updates (minimum 2 seconds between updates)
    // BUT always allow 100% updates through
    final now = DateTime.now();
    if (_lastUpdateTime != null && watchPercentage < 95.0 && !isFinalUpdate) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate.inSeconds < 2) {
        return; // Skip this update, too soon
      }
    }

    // EDGE CASE 4: Only update if significant change (5%) OR near completion (>= 95%) OR final (100%)
    final isSignificantChange = (watchPercentage - _lastUpdatePercentage).abs() >= 5.0;
    final isNearComplete = watchPercentage >= 95.0;

    if (isSignificantChange || isNearComplete || isFinalUpdate) {
      _lastUpdatePercentage = watchPercentage;
      _lastUpdateTime = now;

      // EDGE CASE 5: Mark as completed only when reaching 100%
      if (watchPercentage >= 100.0) {
        _videoCompletedFlag = true;
        print('CourseVideoHeader: Video completed at 100%, marking as completed');
      }

      if (widget.hasCourseAccess && widget.selectedVideo != null) {
        print('CourseVideoHeader: Sending progress update - $watchPercentage% for video ${widget.selectedVideo!['id']}');
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

  Map<String, dynamic>? _findPreviousVideo() {
    print('CourseVideoHeader: _findPreviousVideo called');
    print('CourseVideoHeader: selectedVideo = ${widget.selectedVideo}');
    print('CourseVideoHeader: modules.length = ${widget.modules.length}');

    if (widget.selectedVideo == null || widget.modules.isEmpty) {
      print('CourseVideoHeader: No selected video or modules, returning null');
      return null;
    }

    final currentVideoId = widget.selectedVideo!['id'];
    var currentModuleId = widget.selectedVideo!['moduleId'];

    // If moduleId is null, try to find it by searching all modules
    if (currentModuleId == null) {
      print('CourseVideoHeader: moduleId is null, searching for video in all modules...');
      for (var module in widget.modules) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        if (videos.any((v) => v['id'] == currentVideoId)) {
          currentModuleId = module['id'];
          print('CourseVideoHeader: Found video in module: ${module['title']}');
          break;
        }
      }
    }

    print('CourseVideoHeader: currentVideoId = $currentVideoId, currentModuleId = $currentModuleId');

    // First, try to find the current video in its supposed module
    final currentModule = widget.modules.firstWhere(
      (module) => module['id'] == currentModuleId,
      orElse: () => <String, dynamic>{},
    );

    int currentVideoIndex = -1;
    int currentModuleIndex = -1;
    
    if (currentModule.isNotEmpty) {
      final videos = currentModule['videos'] as List<dynamic>? ?? [];
      
      currentVideoIndex = videos.indexWhere(
        (video) => video['id'] == currentVideoId,
      );
    }

    // If video not found in its supposed module, search all modules
    if (currentVideoIndex == -1) {
      print('CourseVideoHeader: Video not found in supposed module, searching all modules...');
      
      for (int i = 0; i < widget.modules.length; i++) {
        final module = widget.modules[i];
        final videos = module['videos'] as List<dynamic>? ?? [];
        
        final videoIndex = videos.indexWhere(
          (video) => video['id'] == currentVideoId,
        );
        
        if (videoIndex != -1) {
          currentVideoIndex = videoIndex;
          currentModuleIndex = i;
          print('CourseVideoHeader: Found video in module $i (${module['title']}), video index: $videoIndex');
          break;
        }
      }
    } else {
      // Video found in its supposed module
      currentModuleIndex = widget.modules.indexWhere(
        (module) => module['id'] == currentModuleId,
      );
    }

    if (currentVideoIndex == -1 || currentModuleIndex == -1) {
      print('CourseVideoHeader: Current video not found in any module, returning null');
      return null;
    }

    // Get the actual current module and its videos
    final actualCurrentModule = widget.modules[currentModuleIndex];
    final currentModuleVideos = actualCurrentModule['videos'] as List<dynamic>? ?? [];

    // Check if there's a previous video in current module
    if (currentVideoIndex > 0) {
      final previousVideo = currentModuleVideos[currentVideoIndex - 1];
      final previousVideoMap = Map<String, dynamic>.from(previousVideo as Map);
      final isPremium = previousVideoMap['isPremium'] ?? false;
      final hasAccess = !isPremium || widget.hasCourseAccess;

      if (hasAccess) {
        print('CourseVideoHeader: Found previous video in same module: ${previousVideoMap['title']}');
        // Ensure moduleId is set
        previousVideoMap['moduleId'] = actualCurrentModule['id'];
        return previousVideoMap;
      } else {
        print('CourseVideoHeader: Previous video in same module is not accessible, looking in previous modules...');
      }
    } else {
      print('CourseVideoHeader: No previous videos in current module, looking in previous modules...');
    }

    print('CourseVideoHeader: Current module index: $currentModuleIndex, Total modules: ${widget.modules.length}');

    if (currentModuleIndex == -1 || currentModuleIndex == 0) {
      print('CourseVideoHeader: No previous modules to check');
      return null;
    }

    // Check previous modules for accessible videos (start from the previous module)
    for (int i = currentModuleIndex - 1; i >= 0; i--) {
      final module = widget.modules[i];
      final isModulePremium = module['isPremium'] ?? (module['type'] == 'premium');
      final hasModuleAccess = !isModulePremium || widget.hasCourseAccess;

      print('CourseVideoHeader: Checking previous module $i: ${module['title']}, isPremium: $isModulePremium, hasModuleAccess: $hasModuleAccess');

      if (hasModuleAccess) {
        final moduleVideos = module['videos'] as List<dynamic>? ?? [];
        print('CourseVideoHeader: Module has ${moduleVideos.length} videos');
        
        // Get the last accessible video in this module
        for (int j = moduleVideos.length - 1; j >= 0; j--) {
          final video = moduleVideos[j];
          final videoMap = Map<String, dynamic>.from(video as Map);
          final isVideoPremium = videoMap['isPremium'] ?? false;
          final hasVideoAccess = !isVideoPremium || widget.hasCourseAccess;

          print('CourseVideoHeader: Checking previous video: ${videoMap['title']}, isPremium: $isVideoPremium, hasAccess: $hasVideoAccess');

          if (hasVideoAccess) {
            print('CourseVideoHeader: Found last accessible video in previous module: ${videoMap['title']}');
            // Ensure moduleId is set
            videoMap['moduleId'] = module['id'];
            return videoMap;
          }
        }
      } else {
        print('CourseVideoHeader: Module ${module['title']} is not accessible (premium)');
      }
    }

    print('CourseVideoHeader: No previous accessible videos found');
    return null;
  }

  Map<String, dynamic>? _findNextVideo() {
    print('CourseVideoHeader: _findNextVideo called');
    print('CourseVideoHeader: selectedVideo = ${widget.selectedVideo}');
    print('CourseVideoHeader: modules.length = ${widget.modules.length}');

    if (widget.selectedVideo == null || widget.modules.isEmpty) {
      print('CourseVideoHeader: No selected video or modules, returning null');
      return null;
    }

    final currentVideoId = widget.selectedVideo!['id'];
    var currentModuleId = widget.selectedVideo!['moduleId'];

    // If moduleId is null, try to find it by searching all modules
    if (currentModuleId == null) {
      print('CourseVideoHeader: moduleId is null, searching for video in all modules...');
      for (var module in widget.modules) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        if (videos.any((v) => v['id'] == currentVideoId)) {
          currentModuleId = module['id'];
          print('CourseVideoHeader: Found video in module: ${module['title']}');
          break;
        }
      }
    }

    print('CourseVideoHeader: currentVideoId = $currentVideoId, currentModuleId = $currentModuleId');

    // First, try to find the current video in its supposed module
    final currentModule = widget.modules.firstWhere(
      (module) => module['id'] == currentModuleId,
      orElse: () => <String, dynamic>{},
    );

    print('CourseVideoHeader: currentModule found: ${currentModule.isNotEmpty}');
    if (currentModule.isNotEmpty) {
      print('CourseVideoHeader: currentModule title: ${currentModule['title']}');
    }

    int currentVideoIndex = -1;
    int currentModuleIndex = -1;
    
    if (currentModule.isNotEmpty) {
      final videos = currentModule['videos'] as List<dynamic>? ?? [];
      print('CourseVideoHeader: videos in current module: ${videos.length}');
      
      currentVideoIndex = videos.indexWhere(
        (video) => video['id'] == currentVideoId,
      );
      print('CourseVideoHeader: currentVideoIndex in supposed module: $currentVideoIndex');
    }

    // If video not found in its supposed module, search all modules
    if (currentVideoIndex == -1) {
      print('CourseVideoHeader: Video not found in supposed module, searching all modules...');
      
      for (int i = 0; i < widget.modules.length; i++) {
        final module = widget.modules[i];
        final videos = module['videos'] as List<dynamic>? ?? [];
        
        final videoIndex = videos.indexWhere(
          (video) => video['id'] == currentVideoId,
        );
        
        if (videoIndex != -1) {
          currentVideoIndex = videoIndex;
          currentModuleIndex = i;
          print('CourseVideoHeader: Found video in module $i (${module['title']}), video index: $videoIndex');
          break;
        }
      }
    } else {
      // Video found in its supposed module
      currentModuleIndex = widget.modules.indexWhere(
        (module) => module['id'] == currentModuleId,
      );
    }

    if (currentVideoIndex == -1 || currentModuleIndex == -1) {
      print('CourseVideoHeader: Current video not found in any module, returning null');
      return null;
    }

    print('CourseVideoHeader: Final currentModuleIndex: $currentModuleIndex, currentVideoIndex: $currentVideoIndex');

    // Get the actual current module and its videos
    final actualCurrentModule = widget.modules[currentModuleIndex];
    final currentModuleVideos = actualCurrentModule['videos'] as List<dynamic>? ?? [];
    
    print('CourseVideoHeader: Actual current module: ${actualCurrentModule['title']}');
    print('CourseVideoHeader: Videos in actual current module: ${currentModuleVideos.length}');

    // Check if there's a next video in current module
    print('CourseVideoHeader: Checking for next video in current module...');
    print('CourseVideoHeader: currentVideoIndex + 1 = ${currentVideoIndex + 1}, videos.length = ${currentModuleVideos.length}');
    
    if (currentVideoIndex + 1 < currentModuleVideos.length) {
      final nextVideo = currentModuleVideos[currentVideoIndex + 1];
      final nextVideoMap = Map<String, dynamic>.from(nextVideo as Map);
      final isPremium = nextVideoMap['isPremium'] ?? false;
      final hasAccess = !isPremium || widget.hasCourseAccess;

      print('CourseVideoHeader: Found next video: ${nextVideoMap['title']}, isPremium: $isPremium, hasAccess: $hasAccess');

      if (hasAccess) {
        print('CourseVideoHeader: Found next video in same module: ${nextVideoMap['title']}');
        // Ensure moduleId is set
        nextVideoMap['moduleId'] = actualCurrentModule['id'];
        return nextVideoMap;
      } else {
        print('CourseVideoHeader: Next video in same module is not accessible, looking in next modules...');
      }
    } else {
      print('CourseVideoHeader: No more videos in current module, looking in next modules...');
    }

    print('CourseVideoHeader: Current module index: $currentModuleIndex, Total modules: ${widget.modules.length}');

    if (currentModuleIndex + 1 >= widget.modules.length) {
      print('CourseVideoHeader: No more modules to check');
      return null;
    }

    // Check next modules for accessible videos (start from the very next module)
    for (int i = currentModuleIndex + 1; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      final isModulePremium = module['isPremium'] ?? (module['type'] == 'premium');
      final hasModuleAccess = !isModulePremium || widget.hasCourseAccess;

      print('CourseVideoHeader: Checking next module $i: ${module['title']}, isPremium: $isModulePremium, hasModuleAccess: $hasModuleAccess');

      if (hasModuleAccess) {
        final moduleVideos = module['videos'] as List<dynamic>? ?? [];
        print('CourseVideoHeader: Module has ${moduleVideos.length} videos');
        
        for (final video in moduleVideos) {
          final videoMap = Map<String, dynamic>.from(video as Map);
          final isVideoPremium = videoMap['isPremium'] ?? false;
          final hasVideoAccess = !isVideoPremium || widget.hasCourseAccess;

          print('CourseVideoHeader: Checking next video: ${videoMap['title']}, isPremium: $isVideoPremium, hasAccess: $hasVideoAccess');

          if (hasVideoAccess) {
            print('CourseVideoHeader: Found first accessible video in next module: ${videoMap['title']}');
            // Ensure moduleId is set
            videoMap['moduleId'] = module['id'];
            return videoMap;
          }
        }
      } else {
        print('CourseVideoHeader: Module ${module['title']} is not accessible (premium)');
      }
    }

    print('CourseVideoHeader: No next accessible videos found');
    return null;
  }

  // Find next video regardless of access (for checking if premium content blocks)
  Map<String, dynamic>? _findNextVideoRegardlessOfAccess() {
    if (widget.selectedVideo == null || widget.modules.isEmpty) return null;

    final currentVideoId = widget.selectedVideo!['id'];
    var currentModuleId = widget.selectedVideo!['moduleId'];

    // Find module if moduleId is null
    if (currentModuleId == null) {
      for (var module in widget.modules) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        if (videos.any((v) => v['id'] == currentVideoId)) {
          currentModuleId = module['id'];
          break;
        }
      }
    }

    int currentVideoIndex = -1;
    int currentModuleIndex = -1;

    // Find current video position
    for (int i = 0; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      if (module['id'] == currentModuleId) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        currentVideoIndex = videos.indexWhere((v) => v['id'] == currentVideoId);
        if (currentVideoIndex != -1) {
          currentModuleIndex = i;
          break;
        }
      }
    }

    if (currentVideoIndex == -1 || currentModuleIndex == -1) return null;

    final currentModule = widget.modules[currentModuleIndex];
    final currentVideos = currentModule['videos'] as List<dynamic>? ?? [];

    // Check next video in current module
    if (currentVideoIndex + 1 < currentVideos.length) {
      final nextVideo = Map<String, dynamic>.from(currentVideos[currentVideoIndex + 1] as Map);
      nextVideo['moduleId'] = currentModule['id'];
      return nextVideo;
    }

    // Check next modules
    for (int i = currentModuleIndex + 1; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      final videos = module['videos'] as List<dynamic>? ?? [];
      if (videos.isNotEmpty) {
        final nextVideo = Map<String, dynamic>.from(videos[0] as Map);
        nextVideo['moduleId'] = module['id'];
        return nextVideo;
      }
    }

    return null;
  }

  // Public methods for video navigation
  // NOTE: This method does NOT check completion status
  // It simply finds and plays the next video based on access rights
  void navigateToNextVideo() {
    print('CourseVideoHeader: ========================================');
    print('CourseVideoHeader: NEXT VIDEO NAVIGATION TRIGGERED');
    print('CourseVideoHeader: Current Video: ${widget.selectedVideo?['title']}');
    print('CourseVideoHeader: Has Course Access: ${widget.hasCourseAccess}');

    // Step 1: Find the next accessible video (checks premium status)
    final nextVideo = _findNextVideo();

    if (nextVideo != null && widget.onNextVideo != null) {
      // SUCCESS: Found an accessible next video - play it immediately!
      print('CourseVideoHeader: ✅ PLAYING NEXT VIDEO: ${nextVideo['title']}');
      print('CourseVideoHeader: Next Video Module ID: ${nextVideo['moduleId']}');
      print('CourseVideoHeader: Next Video Is Premium: ${nextVideo['isPremium'] ?? false}');
      print('CourseVideoHeader: ========================================');
      widget.onNextVideo!(nextVideo);
    } else {
      // Step 2: No accessible video found - check if premium content is blocking
      final anyNextVideo = _findNextVideoRegardlessOfAccess();

      if (anyNextVideo != null) {
        // BLOCKED: Next video exists but is premium/locked
        print('CourseVideoHeader: 🔒 NEXT VIDEO IS LOCKED: ${anyNextVideo['title']}');
        print('CourseVideoHeader: Module ID: ${anyNextVideo['moduleId']}');
        print('CourseVideoHeader: Showing premium dialog...');
        print('CourseVideoHeader: ========================================');
        _showPremiumDialog(anyNextVideo);
      } else {
        // END: No more videos in the course
        print('CourseVideoHeader: 📺 NO MORE VIDEOS - END OF COURSE');
        print('CourseVideoHeader: ========================================');
        _showEndOfCourseMessage();
      }
    }
  }

  // NOTE: This method does NOT check completion status
  // It simply finds and plays the previous video based on access rights
  void navigateToPreviousVideo() {
    print('CourseVideoHeader: ========================================');
    print('CourseVideoHeader: PREVIOUS VIDEO NAVIGATION TRIGGERED');
    print('CourseVideoHeader: Current Video: ${widget.selectedVideo?['title']}');

    final previousVideo = _findPreviousVideo();

    if (previousVideo != null && widget.onPreviousVideo != null) {
      print('CourseVideoHeader: ✅ PLAYING PREVIOUS VIDEO: ${previousVideo['title']}');
      print('CourseVideoHeader: Previous Video Module ID: ${previousVideo['moduleId']}');
      print('CourseVideoHeader: ========================================');
      widget.onPreviousVideo!(previousVideo);
    } else {
      print('CourseVideoHeader: ⚠️ NO PREVIOUS VIDEO AVAILABLE');
      print('CourseVideoHeader: ========================================');
    }
  }

  void _showPremiumDialog(Map<String, dynamic> video) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.amber.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The next video "${video['title']}" is part of premium content.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Purchase this course to unlock all premium content',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to course purchase page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to course purchase page'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Purchase Course'),
            ),
          ],
        );
      },
    );
  }

  void _showEndOfCourseMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'You\'ve reached the end of available videos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Check if there's ANY next video (regardless of access)
  bool hasNextVideoRegardlessOfAccess() {
    if (widget.selectedVideo == null || widget.modules.isEmpty) return false;

    final currentVideoId = widget.selectedVideo!['id'];
    var currentModuleId = widget.selectedVideo!['moduleId'];

    // Find module if moduleId is null
    if (currentModuleId == null) {
      for (var module in widget.modules) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        if (videos.any((v) => v['id'] == currentVideoId)) {
          currentModuleId = module['id'];
          break;
        }
      }
    }

    int currentVideoIndex = -1;
    int currentModuleIndex = -1;

    // Find current video position
    for (int i = 0; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      if (module['id'] == currentModuleId) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        currentVideoIndex = videos.indexWhere((v) => v['id'] == currentVideoId);
        if (currentVideoIndex != -1) {
          currentModuleIndex = i;
          break;
        }
      }
    }

    if (currentVideoIndex == -1 || currentModuleIndex == -1) return false;

    final currentModule = widget.modules[currentModuleIndex];
    final currentVideos = currentModule['videos'] as List<dynamic>? ?? [];

    // Check if there's a next video in current module
    if (currentVideoIndex + 1 < currentVideos.length) {
      return true;
    }

    // Check if there are any videos in next modules
    for (int i = currentModuleIndex + 1; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      final videos = module['videos'] as List<dynamic>? ?? [];
      if (videos.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  // Check if there's ANY previous video (regardless of access)
  bool hasPreviousVideoRegardlessOfAccess() {
    if (widget.selectedVideo == null || widget.modules.isEmpty) return false;

    final currentVideoId = widget.selectedVideo!['id'];
    var currentModuleId = widget.selectedVideo!['moduleId'];

    // Find module if moduleId is null
    if (currentModuleId == null) {
      for (var module in widget.modules) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        if (videos.any((v) => v['id'] == currentVideoId)) {
          currentModuleId = module['id'];
          break;
        }
      }
    }

    int currentVideoIndex = -1;
    int currentModuleIndex = -1;

    // Find current video position
    for (int i = 0; i < widget.modules.length; i++) {
      final module = widget.modules[i];
      if (module['id'] == currentModuleId) {
        final videos = module['videos'] as List<dynamic>? ?? [];
        currentVideoIndex = videos.indexWhere((v) => v['id'] == currentVideoId);
        if (currentVideoIndex != -1) {
          currentModuleIndex = i;
          break;
        }
      }
    }

    if (currentVideoIndex == -1 || currentModuleIndex == -1) return false;

    // Check if there's a previous video in current module
    if (currentVideoIndex > 0) {
      return true;
    }

    // Check if there are any videos in previous modules
    for (int i = currentModuleIndex - 1; i >= 0; i--) {
      final module = widget.modules[i];
      final videos = module['videos'] as List<dynamic>? ?? [];
      if (videos.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  bool hasNextVideo() {
    final hasNext = hasNextVideoRegardlessOfAccess();
    print('CourseVideoHeader: hasNextVideo = $hasNext');
    return hasNext;
  }

  bool hasPreviousVideo() {
    final hasPrev = hasPreviousVideoRegardlessOfAccess();
    print('CourseVideoHeader: hasPreviousVideo = $hasPrev');
    return hasPrev;
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging removed for production
    
    return SliverToBoxAdapter(
      child: Container(
        height: 250,
        child: SafeArea(
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

  // Async methods to get next/previous videos for fullscreen player
  Future<Map<String, dynamic>?> _getNextVideoForFullscreen() async {
    print('CourseVideoHeader: _getNextVideoForFullscreen called');
    final nextVideo = _findNextVideo();

    if (nextVideo != null) {
      print('CourseVideoHeader: Found next video: ${nextVideo['title']}');
      print('CourseVideoHeader: Calling onNextVideo callback to update parent state');

      // Update the parent state so when exiting fullscreen, correct video is shown
      if (widget.onNextVideo != null) {
        widget.onNextVideo!(nextVideo);
      }
    } else {
      print('CourseVideoHeader: No next video found');
    }

    return nextVideo;
  }

  Future<Map<String, dynamic>?> _getPreviousVideoForFullscreen() async {
    print('CourseVideoHeader: _getPreviousVideoForFullscreen called');
    final previousVideo = _findPreviousVideo();

    if (previousVideo != null) {
      print('CourseVideoHeader: Found previous video: ${previousVideo['title']}');
      print('CourseVideoHeader: Calling onPreviousVideo callback to update parent state');

      // Update the parent state so when exiting fullscreen, correct video is shown
      if (widget.onPreviousVideo != null) {
        widget.onPreviousVideo!(previousVideo);
      }
    } else {
      print('CourseVideoHeader: No previous video found');
    }

    return previousVideo;
  }

  Widget _buildFullScreenVideoPlayer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video player fills entire space
          CloudinaryVideoPlayer(
            key: ValueKey(widget.selectedVideo!['id']), // Add key for proper rebuilds
            videoUrl: widget.selectedVideo!['videoUrl'] ?? '',
            streamingUrl: widget.selectedVideo!['streamingUrl'], // Cloudinary HLS streaming
            qualities: widget.selectedVideo!['qualities'] != null
                ? Map<String, String>.from(widget.selectedVideo!['qualities'])
                : null,
            thumbnailUrl: widget.selectedVideo!['thumbnailUrl'],
            videoTitle: widget.selectedVideo!['title'] ?? 'Video',
            isPremium: false,
            courseId: widget.hasCourseAccess ? widget.course['id'] : null,
            moduleId: widget.hasCourseAccess ? widget.selectedVideo!['moduleId'] : null,
            videoId: widget.hasCourseAccess ? widget.selectedVideo!['id'] : null,
            duration: widget.selectedVideo!['duration'] ?? 0,
            onProgressUpdate: widget.hasCourseAccess ? _onProgressUpdate : null,
            onVideoEnded: widget.hasCourseAccess ? _onVideoEnded : null,
            onNextVideo: widget.hasCourseAccess && hasNextVideo() ? navigateToNextVideo : null,
            onPreviousVideo: widget.hasCourseAccess && hasPreviousVideo() ? navigateToPreviousVideo : null,
            hasNextVideo: hasNextVideo(),
            hasPreviousVideo: hasPreviousVideo(),
          ),

          // Video context header as overlay (top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildVideoContextHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContextHeader() {
    if (widget.selectedVideo == null) return const SizedBox.shrink();

    // Find current module and video position
    String moduleName = 'Module';
    int videoPosition = 0;
    int totalVideosInModule = 0;

    for (var module in widget.modules) {
      if (module['id'] == widget.selectedVideo!['moduleId']) {
        moduleName = module['title'] ?? 'Module';
        final videos = module['videos'] as List<dynamic>? ?? [];
        totalVideosInModule = videos.length;
        videoPosition = videos.indexWhere((v) => v['id'] == widget.selectedVideo!['id']) + 1;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Compact module info badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moduleName.length > 20 ? '${moduleName.substring(0, 20)}...' : moduleName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Video position badge
            if (totalVideosInModule > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$videoPosition/$totalVideosInModule',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Compact video title
            Expanded(
              child: Text(
                widget.selectedVideo!['title'] ?? 'Video',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
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
    // Play button removed - user can click videos from module list
    return const SizedBox.shrink();
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
