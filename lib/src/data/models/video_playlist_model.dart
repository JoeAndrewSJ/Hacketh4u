/// Video Playlist Model
/// Manages a playlist of videos from all course modules
/// Provides navigation, access control, and video metadata

class VideoPlaylistItem {
  final String videoId;
  final String videoTitle;
  final String videoUrl;
  final String moduleId;
  final String moduleName;
  final String courseId;
  final int duration; // in seconds
  final bool isPremium;
  final int order;
  final int moduleOrder;
  final Map<String, dynamic> rawData; // Store complete video data

  const VideoPlaylistItem({
    required this.videoId,
    required this.videoTitle,
    required this.videoUrl,
    required this.moduleId,
    required this.moduleName,
    required this.courseId,
    required this.duration,
    required this.isPremium,
    required this.order,
    required this.moduleOrder,
    required this.rawData,
  });

  factory VideoPlaylistItem.fromModuleAndVideo({
    required Map<String, dynamic> module,
    required Map<String, dynamic> video,
    required String courseId,
  }) {
    return VideoPlaylistItem(
      videoId: video['id'] ?? '',
      videoTitle: video['title'] ?? 'Untitled Video',
      videoUrl: video['videoUrl'] ?? '',
      moduleId: module['id'] ?? '',
      moduleName: module['title'] ?? 'Untitled Module',
      courseId: courseId,
      duration: video['duration'] ?? 0,
      isPremium: video['isPremium'] ?? module['isPremium'] ?? (module['type'] == 'premium'),
      order: video['order'] ?? 0,
      moduleOrder: module['order'] ?? 0,
      rawData: Map<String, dynamic>.from(video)..['moduleId'] = module['id'],
    );
  }

  VideoPlaylistItem copyWith({
    String? videoId,
    String? videoTitle,
    String? videoUrl,
    String? moduleId,
    String? moduleName,
    String? courseId,
    int? duration,
    bool? isPremium,
    int? order,
    int? moduleOrder,
    Map<String, dynamic>? rawData,
  }) {
    return VideoPlaylistItem(
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      videoUrl: videoUrl ?? this.videoUrl,
      moduleId: moduleId ?? this.moduleId,
      moduleName: moduleName ?? this.moduleName,
      courseId: courseId ?? this.courseId,
      duration: duration ?? this.duration,
      isPremium: isPremium ?? this.isPremium,
      order: order ?? this.order,
      moduleOrder: moduleOrder ?? this.moduleOrder,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  String toString() {
    return 'VideoPlaylistItem(id: $videoId, title: $videoTitle, module: $moduleName, premium: $isPremium)';
  }
}

class VideoPlaylist {
  final List<VideoPlaylistItem> items;
  final String courseId;
  final bool hasCourseAccess;
  int _currentIndex = -1;

  VideoPlaylist({
    required this.items,
    required this.courseId,
    required this.hasCourseAccess,
  });

  /// Create playlist from course modules
  factory VideoPlaylist.fromModules({
    required List<Map<String, dynamic>> modules,
    required String courseId,
    required bool hasCourseAccess,
  }) {
    final List<VideoPlaylistItem> playlistItems = [];

    // Sort modules by order
    final sortedModules = List<Map<String, dynamic>>.from(modules)
      ..sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    for (final module in sortedModules) {
      final videos = module['videos'] as List<dynamic>? ?? [];

      // Sort videos by order within module
      final sortedVideos = List<dynamic>.from(videos)
        ..sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      for (final video in sortedVideos) {
        final videoMap = Map<String, dynamic>.from(video as Map);
        playlistItems.add(
          VideoPlaylistItem.fromModuleAndVideo(
            module: module,
            video: videoMap,
            courseId: courseId,
          ),
        );
      }
    }

    return VideoPlaylist(
      items: playlistItems,
      courseId: courseId,
      hasCourseAccess: hasCourseAccess,
    );
  }

  /// Get total number of videos
  int get length => items.length;

  /// Check if playlist is empty
  bool get isEmpty => items.isEmpty;

  /// Check if playlist has videos
  bool get isNotEmpty => items.isNotEmpty;

  /// Get current video index
  int get currentIndex => _currentIndex;

  /// Get current video
  VideoPlaylistItem? get currentVideo {
    if (_currentIndex >= 0 && _currentIndex < items.length) {
      return items[_currentIndex];
    }
    return null;
  }

  /// Set current video by index
  bool setCurrentIndex(int index) {
    if (index >= 0 && index < items.length) {
      _currentIndex = index;
      return true;
    }
    return false;
  }

  /// Set current video by videoId
  bool setCurrentVideoById(String videoId) {
    final index = items.indexWhere((item) => item.videoId == videoId);
    if (index != -1) {
      _currentIndex = index;
      return true;
    }
    return false;
  }

  /// Get first accessible video (respects premium status)
  VideoPlaylistItem? getFirstAccessibleVideo() {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (_hasAccess(item)) {
        _currentIndex = i;
        return item;
      }
    }
    return null;
  }

  /// Check if there's a next video (accessible)
  bool get hasNext {
    return _findNextAccessibleIndex(_currentIndex) != null;
  }

  /// Check if there's a previous video (accessible)
  bool get hasPrevious {
    return _findPreviousAccessibleIndex(_currentIndex) != null;
  }

  /// Get next accessible video
  VideoPlaylistItem? getNext() {
    final nextIndex = _findNextAccessibleIndex(_currentIndex);
    if (nextIndex != null) {
      _currentIndex = nextIndex;
      return items[_currentIndex];
    }
    return null;
  }

  /// Get previous accessible video
  VideoPlaylistItem? getPrevious() {
    final previousIndex = _findPreviousAccessibleIndex(_currentIndex);
    if (previousIndex != null) {
      _currentIndex = previousIndex;
      return items[_currentIndex];
    }
    return null;
  }

  /// Peek at next video without changing current index
  VideoPlaylistItem? peekNext() {
    final nextIndex = _findNextAccessibleIndex(_currentIndex);
    if (nextIndex != null) {
      return items[nextIndex];
    }
    return null;
  }

  /// Peek at previous video without changing current index
  VideoPlaylistItem? peekPrevious() {
    final previousIndex = _findPreviousAccessibleIndex(_currentIndex);
    if (previousIndex != null) {
      return items[previousIndex];
    }
    return null;
  }

  /// Check if user has access to a video
  bool _hasAccess(VideoPlaylistItem item) {
    // If course is purchased, all videos are accessible
    if (hasCourseAccess) {
      print('VideoPlaylist: User has course access - video "${item.videoTitle}" accessible');
      return true;
    }

    // Otherwise, only free videos are accessible
    final hasAccess = !item.isPremium;
    if (!hasAccess) {
      print('VideoPlaylist: Video "${item.videoTitle}" is PREMIUM - blocked for free users');
    }
    return hasAccess;
  }

  /// Find next accessible video index
  int? _findNextAccessibleIndex(int fromIndex) {
    print('VideoPlaylist: Finding next accessible video from index $fromIndex');
    for (int i = fromIndex + 1; i < items.length; i++) {
      if (_hasAccess(items[i])) {
        print('VideoPlaylist: Found next accessible video at index $i: "${items[i].videoTitle}"');
        return i;
      } else {
        print('VideoPlaylist: Skipping video at index $i: "${items[i].videoTitle}" (premium/no access)');
      }
    }
    print('VideoPlaylist: No more accessible videos after index $fromIndex');
    return null;
  }

  /// Find previous accessible video index
  int? _findPreviousAccessibleIndex(int fromIndex) {
    print('VideoPlaylist: Finding previous accessible video from index $fromIndex');
    for (int i = fromIndex - 1; i >= 0; i--) {
      if (_hasAccess(items[i])) {
        print('VideoPlaylist: Found previous accessible video at index $i: "${items[i].videoTitle}"');
        return i;
      } else {
        print('VideoPlaylist: Skipping video at index $i: "${items[i].videoTitle}" (premium/no access)');
      }
    }
    print('VideoPlaylist: No more accessible videos before index $fromIndex');
    return null;
  }

  /// Get all accessible videos
  List<VideoPlaylistItem> getAccessibleVideos() {
    return items.where((item) => _hasAccess(item)).toList();
  }

  /// Get videos by module
  List<VideoPlaylistItem> getVideosByModule(String moduleId) {
    return items.where((item) => item.moduleId == moduleId).toList();
  }

  /// Get current video position info (for UI display)
  String getCurrentPositionText() {
    if (currentVideo == null) return '';

    final currentNum = _currentIndex + 1;
    final total = items.length;
    return '$currentNum/$total';
  }

  /// Get current module name
  String? getCurrentModuleName() {
    return currentVideo?.moduleName;
  }

  /// Debug info
  void printPlaylistInfo() {
    print('=== VIDEO PLAYLIST INFO ===');
    print('Course ID: $courseId');
    print('Has Course Access: $hasCourseAccess');
    print('Total Videos: ${items.length}');
    print('Current Index: $_currentIndex');
    print('Current Video: ${currentVideo?.videoTitle ?? 'None'}');
    print('Has Next: $hasNext');
    print('Has Previous: $hasPrevious');

    final accessibleVideos = getAccessibleVideos();
    print('Accessible Videos: ${accessibleVideos.length}/${items.length}');

    if (!hasCourseAccess && accessibleVideos.length < items.length) {
      print('⚠️ User is FREE USER - ${items.length - accessibleVideos.length} premium videos blocked');
    }

    print('\nVideo List:');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final accessible = _hasAccess(item);
      final marker = i == _currentIndex ? '▶' : ' ';
      final accessMarker = accessible ? '✓' : '🔒';
      print('$marker [$i] $accessMarker ${item.videoTitle} (${item.isPremium ? 'PREMIUM' : 'FREE'})');
    }
    print('==========================');
  }
}
