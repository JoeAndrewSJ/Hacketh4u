# Course Details Screen Flow

## User Experience Flow

### **Initial State (Course Opened)**
```
User Opens Course
   ↓
CourseVideoHeader displays:
  - Course thumbnail image
  - Course title
  - Duration & student count
  - Play button overlay
  ↓
Tabs show: Modules | Overview | Reviews
```

### **Starting Video Playback**

#### **Option 1: Click Play Button on Thumbnail**
```
User clicks play button on thumbnail
   ↓
_onVideoHeaderTap() called
   ↓
Gets first accessible video from playlist
   ↓
Sets _isVideoPlaying = true
   ↓
VideoPlayerController appears
   ↓
Auto-plays first video
```

#### **Option 2: Click Video in Module List**
```
User clicks video in Modules tab
   ↓
_onVideoTap(video) called
   ↓
Sets _selectedVideoId and _isVideoPlaying = true
   ↓
VideoPlayerController appears
   ↓
Plays selected video
```

#### **Option 3: Click Module**
```
User clicks module card
   ↓
_onModuleTap(module) called
   ↓
Finds first video in module
   ↓
Sets _selectedVideoId and _isVideoPlaying = true
   ↓
VideoPlayerController appears
   ↓
Plays first video of module
```

### **During Video Playback**

```
VideoPlayerController shows:
  - Video player with controls
  - Module name badge
  - Position indicator (e.g., "3/12")
  - Current video title
  - Next/Previous buttons
  ↓
User watches video
   ↓
Progress tracked and saved to Firestore
   ↓
When video ends:
  - If hasNext: Auto-play next video (2 sec delay)
  - If last video: Return to thumbnail
```

### **Last Video Completion**

```
User watches last video
   ↓
Video reaches 100% completion
   ↓
_onVideoEnded() detects no next video
   ↓
Triggers onPlaylistEnd callback (500ms delay)
   ↓
CourseDetailsScreen sets _isVideoPlaying = false
   ↓
Returns to CourseVideoHeader (thumbnail view)
   ↓
Shows success message: "You've completed all videos!"
```

## State Management

### **Key State Variables**
```dart
bool _isVideoPlaying = false;  // Controls which view to show
String? _selectedVideoId;      // Current video ID
VideoPlaylist? _videoPlaylist;  // Playlist of all videos
```

### **View Switching Logic**
```dart
// In headerSliverBuilder:
_isVideoPlaying && _videoPlaylist != null
  ? SliverToBoxAdapter(child: VideoPlayerController(...))
  : CourseVideoHeader(...)
```

## Component Responsibilities

### **CourseDetailsScreen**
- Manages state (_isVideoPlaying, _selectedVideoId)
- Builds playlist from modules
- Handles video/module selection
- Switches between thumbnail and player views

### **CourseVideoHeader** (Thumbnail Mode)
- Shows course thumbnail image
- Displays course metadata
- Provides play button
- No video player - just preview

### **VideoPlayerController** (Playing Mode)
- Manages video playback
- Handles navigation (next/prev)
- Tracks progress
- Auto-plays next video
- Returns to thumbnail when playlist ends

## Progress Tracking

### **During Playback**
- Updates sent every 5% or 2 seconds
- Near completion (95%+): More frequent updates
- Final 100% update: Always sent
- Correct IDs: courseId, moduleId, videoId

### **Video Completion Detection**
- Threshold: 99.5% of duration
- Triggers: 100% progress update
- Then: Calls onVideoEnded()
- Last video: Returns to thumbnail

## Navigation Flow

### **Next/Previous in Playlist**
```
User clicks Next
   ↓
VideoPlayerController._playNext()
   ↓
Playlist.getNext() finds next accessible video
   ↓
Updates state with new video
   ↓
VideoPlayerWidget rebuilds with new URL
   ↓
Progress tracking resets
```

### **Crossing Module Boundaries**
```
Video in Module A ends
   ↓
Auto-play triggered
   ↓
Playlist finds first video in Module B
   ↓
Seamlessly transitions
   ↓
Module badge updates to Module B
   ↓
Position updates (e.g., 5/12 → 6/12)
```

## Access Control

### **Free Users**
- Thumbnail view: Always visible
- Play button: Works for free videos
- Premium videos: Skipped in playlist
- Message shown if no free videos

### **Paid Users**
- Thumbnail view: Always visible
- All videos accessible
- Playlist includes all videos
- Seamless playback across all modules

## Benefits of This Flow

✅ **Clean UX**: Thumbnail first, video player on demand
✅ **No Clutter**: Video player only when needed
✅ **Natural Flow**: Returns to thumbnail after completion
✅ **Course Preview**: Users see course info before playing
✅ **Seamless Playback**: Auto-play through all videos
✅ **Smart Stop**: Last video returns to thumbnail
✅ **Clear State**: Easy to understand what's happening

## Technical Implementation

### **Conditional Rendering**
```dart
_isVideoPlaying
  ? VideoPlayerController(playlist: _videoPlaylist, ...)
  : CourseVideoHeader(course: widget.course, ...)
```

### **State Transitions**
```dart
// Start playing
setState(() {
  _isVideoPlaying = true;
  _selectedVideoId = videoId;
});

// Stop playing (playlist end)
setState(() {
  _isVideoPlaying = false;
  _selectedVideoId = null;
});
```

### **Playlist End Handler**
```dart
onPlaylistEnd: () {
  setState(() {
    _isVideoPlaying = false;
    _selectedVideoId = null;
  });
  // Show completion message
}
```

## Testing Checklist

- ✅ Opens to thumbnail view
- ✅ Play button starts first video
- ✅ Clicking module starts first video in module
- ✅ Clicking video starts that specific video
- ✅ Next/Previous buttons work
- ✅ Auto-play advances through videos
- ✅ Last video stops and returns to thumbnail
- ✅ Completion message shown
- ✅ Progress saved correctly
- ✅ Module badges update
- ✅ Position indicator accurate
- ✅ Free users see only free videos
- ✅ Paid users see all videos

---

**Implementation Date**: 2025-01-08
**Status**: ✅ Complete and Tested
