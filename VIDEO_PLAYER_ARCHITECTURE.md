# Video Player Architecture Documentation

## Overview
This document describes the new scalable, optimized video player architecture that manages playlists across all course modules.

## Architecture Components

### 1. **VideoPlaylist Model** (`lib/src/data/models/video_playlist_model.dart`)

**Purpose**: Manages a flat playlist of all videos from all course modules with intelligent navigation.

**Key Classes**:

#### `VideoPlaylistItem`
- Represents a single video with all metadata
- Stores: videoId, title, URL, moduleId, moduleName, courseId, duration, premium status
- Created from module and video data

#### `VideoPlaylist`
- Main playlist manager class
- Features:
  - **Flat Structure**: Converts nested modules into a sequential playlist
  - **Access Control**: Filters videos based on premium status and course access
  - **Smart Navigation**: Next/Previous with automatic module boundary crossing
  - **Position Tracking**: Maintains current video index
  - **Sorted Order**: Videos sorted by module order, then video order

**Key Methods**:
```dart
// Create playlist from modules
VideoPlaylist.fromModules(
  modules: List<Map<String, dynamic>>,
  courseId: String,
  hasCourseAccess: bool,
)

// Navigation
getNext() → VideoPlaylistItem?  // Get next accessible video
getPrevious() → VideoPlaylistItem?  // Get previous accessible video
hasNext → bool  // Check if next video exists
hasPrevious → bool  // Check if previous video exists

// Selection
setCurrentVideoById(String videoId) → bool  // Jump to specific video
getFirstAccessibleVideo() → VideoPlaylistItem?  // Auto-select first video

// Access Control
getAccessibleVideos() → List<VideoPlaylistItem>  // Filter accessible videos
```

---

### 2. **VideoPlayerController** (`lib/src/presentation/widgets/video/video_player_controller.dart`)

**Purpose**: Main video player widget that manages playback, navigation, and progress tracking.

**Features**:
- **Playlist Integration**: Uses VideoPlaylist for seamless navigation
- **Progress Tracking**: Sends updates to UserProgressBloc with correct IDs
- **Auto-Play**: Automatically plays next video when current ends
- **State Management**: Handles video changes, resets progress tracking
- **Access Control**: Works only with accessible videos from playlist

**Key Features**:

#### Progress Tracking
- Tracks percentage completion (0-100%)
- Sends updates at:
  - Every 5% change
  - Every 2 seconds (throttled)
  - When reaching 95%+ (near completion)
  - Always at 100% (final update)
- Prevents backward progress for near-complete videos
- Resets tracking when video changes

#### Auto-Navigation
- Auto-plays next video 2 seconds after current video ends
- Triggers `onPlaylistEnd` callback when playlist completes
- Shows completion message

#### Video Header
- Displays module name badge
- Shows position (e.g., "3/12")
- Shows current video title

**Parameters**:
```dart
VideoPlayerController({
  required VideoPlaylist playlist,  // The video playlist
  String? initialVideoId,  // Optional: start with specific video
  VoidCallback? onPlaylistEnd,  // Called when all videos complete
  bool autoPlayNext = true,  // Enable/disable auto-play
})
```

---

### 3. **CourseDetailsScreen Integration** (`lib/src/presentation/screens/user/course_details_screen.dart`)

**Changes Made**:

#### State Variables
```dart
VideoPlaylist? _videoPlaylist;  // The playlist
String? _selectedVideoId;  // Currently selected video ID
```

#### Playlist Building
```dart
void _buildVideoPlaylist() {
  _videoPlaylist = VideoPlaylist.fromModules(
    modules: _modules,
    courseId: widget.course['id'],
    hasCourseAccess: _hasCourseAccess,
  );

  // Restore selection if exists
  if (_selectedVideoId != null) {
    _videoPlaylist?.setCurrentVideoById(_selectedVideoId!);
  }
}
```

#### UI Integration
Replaced `CourseVideoHeader` with:
```dart
VideoPlayerController(
  key: ValueKey(_videoPlaylist!.courseId),
  playlist: _videoPlaylist!,
  initialVideoId: _selectedVideoId,
  autoPlayNext: true,
  onPlaylistEnd: () { /* Show completion message */ },
)
```

#### Video Selection
When user clicks video in module list:
```dart
void _onVideoTap(Map<String, dynamic> video) {
  setState(() {
    _selectedVideoId = video['id'];
    _buildVideoPlaylist();  // Rebuild with new selection
  });
}
```

---

## Data Flow

### **Video Playback Flow**:
```
1. User opens course
   ↓
2. Modules load via CourseBloc
   ↓
3. _buildVideoPlaylist() creates VideoPlaylist
   ↓
4. VideoPlaylist flattens all modules into sequential list
   ↓
5. VideoPlayerController receives playlist
   ↓
6. First accessible video auto-selected
   ↓
7. VideoPlayerWidget initialized with video URL
   ↓
8. User watches video
   ↓
9. Progress updates sent to UserProgressBloc
   ↓
10. Video completes → Auto-play next video
```

### **Navigation Flow**:
```
User clicks Next/Previous
   ↓
VideoPlayerController calls playlist.getNext()/getPrevious()
   ↓
Playlist finds next accessible video (skips premium if needed)
   ↓
Playlist crosses module boundaries seamlessly
   ↓
VideoPlayerController updates state with new video
   ↓
VideoPlayerWidget rebuilds with new URL
   ↓
Progress tracking resets for new video
```

### **Progress Tracking Flow**:
```
VideoPlayerWidget: Video plays
   ↓
VideoPlayerWidget._videoListener: Calculates percentage every frame
   ↓
VideoPlayerWidget: Calls onProgressUpdate callback
   ↓
VideoPlayerController._onProgressUpdate: Validates and throttles
   ↓
VideoPlayerController: Sends to UserProgressBloc
   ↓
UserProgressBloc: Triggers UpdateVideoProgress event
   ↓
UserProgressRepository: Saves to Firestore
   ↓
Firestore: Updates with correct videoId, moduleId, courseId
```

---

## Key Improvements

### **1. Scalability**
- ✅ Handles unlimited modules and videos
- ✅ Flat playlist structure = O(1) navigation
- ✅ No nested loops for finding next/previous

### **2. Maintainability**
- ✅ Single source of truth (VideoPlaylist)
- ✅ Separation of concerns (Model, Controller, View)
- ✅ Clear data flow
- ✅ Easy to debug with print statements

### **3. Reliability**
- ✅ Proper video ID tracking (no mix-ups)
- ✅ Correct progress updates (100% completion)
- ✅ Access control at playlist level
- ✅ Prevents backward progress
- ✅ Throttled updates (performance)

### **4. User Experience**
- ✅ Seamless navigation across modules
- ✅ Auto-play next video
- ✅ Shows position in playlist
- ✅ Module context always visible
- ✅ Completion notifications

---

## Progress Tracking Fixes

### **Bug #1: 90% Cap Fixed**
- **Before**: Stopped at 90%, marked complete
- **After**: Tracks to 100%, marks complete only at 100%

### **Bug #2: Wrong Video Fixed**
- **Before**: VideoId could get mixed up with multiple videos
- **After**: Each video tracked separately, resets on change

### **Bug #3: Last Second Fixed**
- **Before**: 98% threshold, throttling blocked final update
- **After**: 99.5% threshold, 100% always bypasses throttling

---

## File Structure

```
lib/src/
├── data/
│   └── models/
│       └── video_playlist_model.dart  ← NEW: Playlist logic
├── presentation/
│   ├── screens/
│   │   └── user/
│   │       └── course_details_screen.dart  ← UPDATED: Uses playlist
│   └── widgets/
│       ├── video/
│       │   ├── video_player_controller.dart  ← NEW: Main controller
│       │   └── video_player_widget.dart  ← UPDATED: Better progress
│       └── course/
│           └── course_video_header.dart  ← DEPRECATED: Use VideoPlayerController
```

---

## Usage Example

```dart
// In CourseDetailsScreen
VideoPlayerController(
  playlist: VideoPlaylist.fromModules(
    modules: _modules,
    courseId: courseId,
    hasCourseAccess: true,
  ),
  initialVideoId: 'video-123',  // Optional
  autoPlayNext: true,
  onPlaylistEnd: () {
    print('All videos completed!');
  },
)
```

---

## Testing Checklist

- ✅ Navigation works across module boundaries
- ✅ Next/Previous buttons function correctly
- ✅ Auto-play triggers after video ends
- ✅ Progress tracking saves correct video IDs
- ✅ Progress reaches 100% completion
- ✅ Premium videos are filtered correctly
- ✅ Position indicator updates
- ✅ Module name displays correctly
- ✅ Playlist rebuilds on access change
- ✅ No errors in flutter analyze

---

## Performance Optimizations

1. **Flat Playlist**: O(1) access instead of O(n) nested loops
2. **Throttled Updates**: Progress updates limited to every 2 seconds or 5%
3. **ValueKey**: Forces rebuild only when video actually changes
4. **Lazy Building**: Playlist built only when modules change
5. **Single State**: One source of truth prevents redundant rebuilds

---

## Future Enhancements

### Potential Features:
- [ ] Shuffle mode
- [ ] Repeat mode (single/all)
- [ ] Playback speed control
- [ ] Picture-in-picture mode
- [ ] Download for offline viewing
- [ ] Video quality selection
- [ ] Subtitles/captions support
- [ ] Playlist save/resume
- [ ] Watch history
- [ ] Bookmarks/favorites

---

## Migration Guide

### Old Code:
```dart
CourseVideoHeader(
  course: course,
  selectedVideo: _selectedVideo,
  modules: _modules,
  onNextVideo: _onVideoTap,
  onPreviousVideo: _onVideoTap,
)
```

### New Code:
```dart
VideoPlayerController(
  playlist: VideoPlaylist.fromModules(
    modules: _modules,
    courseId: course['id'],
    hasCourseAccess: _hasCourseAccess,
  ),
  initialVideoId: _selectedVideoId,
  autoPlayNext: true,
)
```

**Changes Required**:
1. Import `video_playlist_model.dart` and `video_player_controller.dart`
2. Replace `Map<String, dynamic>? _selectedVideo` with `String? _selectedVideoId`
3. Add `_buildVideoPlaylist()` method
4. Call `_buildVideoPlaylist()` when modules/access changes
5. Update `_onVideoTap()` to set `_selectedVideoId` instead of `_selectedVideo`

---

**Architecture Version**: 2.0
**Created**: 2025-01-08
**Last Updated**: 2025-01-08
