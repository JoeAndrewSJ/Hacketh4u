import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/di/service_locator.dart';
import '../services/course_progress_sync_service.dart';

class CourseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CourseRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Callback to trigger user progress sync when course structure changes
  Future<void> _triggerUserProgressSync(String courseId) async {
    try {
      print('CourseRepository: Triggering user progress sync for course: $courseId');
      
      // Get the sync service from service locator
      final syncService = sl<CourseProgressSyncService>();
      await syncService.syncCourseProgressForAllUsers(courseId);
      
      print('CourseRepository: Completed user progress sync for course: $courseId');
    } catch (e) {
      print('CourseRepository: Error triggering user progress sync: $e');
      // Don't throw error as this is supplementary functionality
    }
  }

  // Course CRUD Operations
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      print('CourseRepository: Fetching courses from Firestore...');
      final querySnapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .get();

      final courses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('CourseRepository: Found ${courses.length} courses in Firestore');
      for (var course in courses) {
        print('Course: ${course['title']} - ${course['id']}');
      }
      
      return courses;
    } catch (e) {
      print('CourseRepository: Error fetching courses: $e');
      throw Exception('Failed to load courses: $e');
    }
  }

  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load course: $e');
    }
  }

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> courseData) async {
    try {
      print('CourseRepository: Creating course: ${courseData['title']}');
      
      // Add timestamps
      courseData['createdAt'] = FieldValue.serverTimestamp();
      courseData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Set default values
      courseData['status'] = courseData['status'] ?? 'draft';
      courseData['rating'] = courseData['rating'] ?? 0.0;
      courseData['studentCount'] = courseData['studentCount'] ?? 0;
      
      final docRef = await _firestore.collection('courses').add(courseData);
      
      // Return the created course with ID
      final createdCourse = Map<String, dynamic>.from(courseData);
      createdCourse['id'] = docRef.id;
      
      print('CourseRepository: Successfully created course with ID: ${docRef.id}');
      return createdCourse;
    } catch (e) {
      print('CourseRepository: Error creating course: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  Future<Map<String, dynamic>> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    try {
      courseData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('courses').doc(courseId).update(courseData);

      // Return updated course
      final updatedCourse = Map<String, dynamic>.from(courseData);
      updatedCourse['id'] = courseId;
      return updatedCourse;
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  /// Increment the student count for a course when a user purchases it
  Future<void> incrementStudentCount(String courseId) async {
    try {
      print('CourseRepository: Incrementing student count for course: $courseId');

      // First, verify the course document exists
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();

      if (!courseDoc.exists) {
        print('CourseRepository: ERROR - Course document does not exist: $courseId');
        throw Exception('Course not found: $courseId');
      }

      final courseData = courseDoc.data();
      final currentCount = courseData?['studentCount'] as int? ?? 0;
      print('CourseRepository: Current student count for course $courseId: $currentCount');

      // Use FieldValue.increment to atomically increment the count
      await _firestore.collection('courses').doc(courseId).update({
        'studentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Verify the update
      final updatedDoc = await _firestore.collection('courses').doc(courseId).get();
      final newCount = updatedDoc.data()?['studentCount'] as int? ?? 0;
      print('CourseRepository: Successfully incremented student count for course: $courseId');
      print('CourseRepository: New student count: $newCount (was $currentCount)');

      if (newCount <= currentCount) {
        print('CourseRepository: WARNING - Student count did not increase properly! Old: $currentCount, New: $newCount');
      }
    } catch (e) {
      print('CourseRepository: Error incrementing student count for course $courseId: $e');
      print('CourseRepository: Error type: ${e.runtimeType}');
      print('CourseRepository: Error details: ${e.toString()}');
      throw Exception('Failed to increment student count: $e');
    }
  }

  // Update module with video information
  Future<void> _updateModuleWithVideoInfo(String courseId, String moduleId, Map<String, dynamic> video) async {
    try {
      // Get current module data
      final moduleDoc = await _firestore.collection('modules').doc(moduleId).get();
      if (!moduleDoc.exists) return;
      
      final moduleData = moduleDoc.data()!;
      List<Map<String, dynamic>> videos = List<Map<String, dynamic>>.from(moduleData['videos'] ?? []);
      
      // Create a clean video object without FieldValue.serverTimestamp() for array storage
      final cleanVideo = Map<String, dynamic>.from(video);
      // Remove server timestamp fields that can't be stored in arrays
      cleanVideo.remove('createdAt');
      cleanVideo.remove('updatedAt');
      
      // Add or update video in module's videos array
      final existingIndex = videos.indexWhere((v) => v['id'] == video['id']);
      if (existingIndex >= 0) {
        videos[existingIndex] = cleanVideo;
      } else {
        videos.add(cleanVideo);
      }
      
      // Sort videos by order
      videos.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      
      // Update module with videos array
      await _firestore.collection('modules').doc(moduleId).update({
        'videos': videos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CourseRepository: Updated module $moduleId with video ${video['id']}');
    } catch (e) {
      print('CourseRepository: Error updating module with video info: $e');
      // Don't throw error as this is supplementary data
    }
  }

  // Remove video from module's videos array
  Future<void> _removeVideoFromModule(String courseId, String moduleId, String videoId) async {
    try {
      // Get current module data
      final moduleDoc = await _firestore.collection('modules').doc(moduleId).get();
      if (!moduleDoc.exists) return;
      
      final moduleData = moduleDoc.data()!;
      List<Map<String, dynamic>> videos = List<Map<String, dynamic>>.from(moduleData['videos'] ?? []);
      
      // Remove video from module's videos array
      videos.removeWhere((v) => v['id'] == videoId);
      
      // Update module with videos array
      await _firestore.collection('modules').doc(moduleId).update({
        'videos': videos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CourseRepository: Removed video $videoId from module $moduleId');
    } catch (e) {
      print('CourseRepository: Error removing video from module: $e');
      // Don't throw error as this is supplementary data
    }
  }

  // Calculate and update total duration for a course
  Future<void> updateCourseTotalDuration(String courseId) async {
    try {
      final modules = await getCourseModules(courseId);
      int totalDuration = 0;
      int totalVideos = 0;
      
      for (final module in modules) {
        totalDuration += (module['totalDuration'] ?? 0) as int;
        totalVideos += (module['videoCount'] ?? 0) as int;
      }
      
      await _firestore.collection('courses').doc(courseId).update({
        'totalDuration': totalDuration,
        'totalVideos': totalVideos,
        'moduleCount': modules.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CourseRepository: Updated course $courseId - Duration: ${totalDuration}s, Videos: $totalVideos, Modules: ${modules.length}');
    } catch (e) {
      print('CourseRepository: Error updating course total duration: $e');
      throw Exception('Failed to update course total duration: $e');
    }
  }

  // Calculate and update total duration for a module
  Future<void> updateModuleTotalDuration(String courseId, String moduleId) async {
    try {
      final videos = await getModuleVideos(courseId, moduleId);
      int totalDuration = 0;
      int videoCount = videos.length;
      
      for (final video in videos) {
        totalDuration += (video['duration'] ?? 0) as int;
      }
      
      await _firestore.collection('modules').doc(moduleId).update({
        'totalDuration': totalDuration,
        'videoCount': videoCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CourseRepository: Updated module $moduleId - Duration: ${totalDuration}s, Videos: $videoCount');
      
      // Also update course total duration
      await updateCourseTotalDuration(courseId);
    } catch (e) {
      print('CourseRepository: Error updating module total duration: $e');
      throw Exception('Failed to update module total duration: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      print('CourseRepository: Starting deletion of course: $courseId');
      
      // Get course data first to delete associated files
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) {
        print('CourseRepository: Course not found: $courseId');
        throw Exception('Course not found');
      }
      
      final courseData = courseDoc.data()!;
      
      // Delete associated modules and videos
      await _deleteCourseModules(courseId);
      
      // Delete course files from storage
      if (courseData['thumbnailUrl'] != null) {
        try {
          await _storage.refFromURL(courseData['thumbnailUrl']).delete();
          print('CourseRepository: Deleted course thumbnail: ${courseData['thumbnailUrl']}');
        } catch (e) {
          print('CourseRepository: Failed to delete thumbnail: $e');
        }
      }
      
      if (courseData['certificateTemplateUrl'] != null) {
        try {
          await _storage.refFromURL(courseData['certificateTemplateUrl']).delete();
          print('CourseRepository: Deleted course certificate: ${courseData['certificateTemplateUrl']}');
        } catch (e) {
          print('CourseRepository: Failed to delete certificate: $e');
        }
      }
      
      // Delete course document
      await _firestore.collection('courses').doc(courseId).delete();
      print('CourseRepository: Successfully deleted course: $courseId');
      
    } catch (e) {
      print('CourseRepository: Error deleting course: $e');
      throw Exception('Failed to delete course: $e');
    }
  }

  // Module Operations
  Future<List<Map<String, dynamic>>> getCourseModules(String courseId) async {
    try {
      // Query without orderBy to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection('modules')
          .where('courseId', isEqualTo: courseId)
          .get();

      final modules = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by order in memory
      modules.sort((a, b) {
        final aOrder = a['order'] ?? 0;
        final bOrder = b['order'] ?? 0;
        return aOrder.compareTo(bOrder);
      });

      return modules;
    } catch (e) {
      throw Exception('Failed to load modules: $e');
    }
  }

  Future<Map<String, dynamic>> createModule(String courseId, Map<String, dynamic> moduleData) async {
    try {
      moduleData['courseId'] = courseId;
      moduleData['createdAt'] = FieldValue.serverTimestamp();
      moduleData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Set order if not provided
      if (moduleData['order'] == null) {
        final modules = await getCourseModules(courseId);
        moduleData['order'] = modules.length + 1;
      }
      
      final docRef = await _firestore.collection('modules').add(moduleData);
      
      final createdModule = Map<String, dynamic>.from(moduleData);
      createdModule['id'] = docRef.id;
      
      // Trigger user progress sync for all users who have progress for this course
      await _triggerUserProgressSync(courseId);
      
      return createdModule;
    } catch (e) {
      throw Exception('Failed to create module: $e');
    }
  }

  Future<Map<String, dynamic>> updateModule(String courseId, String moduleId, Map<String, dynamic> moduleData) async {
    try {
      moduleData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('modules').doc(moduleId).update(moduleData);
      
      final updatedModule = Map<String, dynamic>.from(moduleData);
      updatedModule['id'] = moduleId;
      updatedModule['courseId'] = courseId;
      return updatedModule;
    } catch (e) {
      throw Exception('Failed to update module: $e');
    }
  }

  Future<void> deleteModule(String courseId, String moduleId) async {
    try {
      // Delete associated videos
      await _deleteModuleVideos(courseId, moduleId);
      
      // Delete module
      await _firestore.collection('modules').doc(moduleId).delete();
      
      // Trigger user progress sync for all users who have progress for this course
      await _triggerUserProgressSync(courseId);
    } catch (e) {
      throw Exception('Failed to delete module: $e');
    }
  }

  // Video Operations
  Future<List<Map<String, dynamic>>> getModuleVideos(String courseId, String moduleId) async {
    try {
      // Query without orderBy to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection('videos')
          .where('moduleId', isEqualTo: moduleId)
          .where('courseId', isEqualTo: courseId)
          .get();

      final videos = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by order in memory
      videos.sort((a, b) {
        final aOrder = a['order'] ?? 0;
        final bOrder = b['order'] ?? 0;
        return aOrder.compareTo(bOrder);
      });

      return videos;
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  Future<Map<String, dynamic>> createVideo(String courseId, String moduleId, Map<String, dynamic> videoData) async {
    try {
      videoData['courseId'] = courseId;
      videoData['moduleId'] = moduleId;
      videoData['createdAt'] = FieldValue.serverTimestamp();
      videoData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Set order if not provided
      if (videoData['order'] == null) {
        final videos = await getModuleVideos(courseId, moduleId);
        videoData['order'] = videos.length + 1;
      }
      
      final docRef = await _firestore.collection('videos').add(videoData);
      
      final createdVideo = Map<String, dynamic>.from(videoData);
      createdVideo['id'] = docRef.id;
      
      // Update module with video information
      await _updateModuleWithVideoInfo(courseId, moduleId, createdVideo);
      
      // Update module total duration
      await updateModuleTotalDuration(courseId, moduleId);
      
      // Trigger user progress sync for all users who have progress for this course
      await _triggerUserProgressSync(courseId);
      
      return createdVideo;
    } catch (e) {
      throw Exception('Failed to create video: $e');
    }
  }

  Future<Map<String, dynamic>> updateVideo(String courseId, String moduleId, String videoId, Map<String, dynamic> videoData) async {
    try {
      print('CourseRepository: Updating video: $videoId');
      videoData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('videos').doc(videoId).update(videoData);
      
      final updatedVideo = Map<String, dynamic>.from(videoData);
      updatedVideo['id'] = videoId;
      updatedVideo['courseId'] = courseId;
      updatedVideo['moduleId'] = moduleId;
      
      // Update module with video information
      await _updateModuleWithVideoInfo(courseId, moduleId, updatedVideo);
      
      // Update module total duration
      await updateModuleTotalDuration(courseId, moduleId);
      
      // Trigger user progress sync for all users who have progress for this course
      await _triggerUserProgressSync(courseId);
      
      print('CourseRepository: Successfully updated video: $videoId');
      return updatedVideo;
    } catch (e) {
      print('CourseRepository: Error updating video: $e');
      throw Exception('Failed to update video: $e');
    }
  }

  Future<void> deleteVideo(String courseId, String moduleId, String videoId) async {
    try {
      print('CourseRepository: Starting deletion of video: $videoId');
      
      // Get video data first
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) {
        print('CourseRepository: Video document not found: $videoId');
        return; // Video doesn't exist, nothing to delete
      }
      
      final videoData = videoDoc.data()!;
      
      // Delete video file from storage (with error handling)
      if (videoData['videoUrl'] != null && videoData['videoUrl'].toString().isNotEmpty) {
        try {
          await _storage.refFromURL(videoData['videoUrl']).delete();
          print('CourseRepository: Deleted video file: ${videoData['videoUrl']}');
        } catch (e) {
          print('CourseRepository: Failed to delete video file (may not exist): $e');
          // Continue with deletion even if storage file doesn't exist
        }
      }
      
      // Delete thumbnail from storage (with error handling)
      if (videoData['thumbnailUrl'] != null && videoData['thumbnailUrl'].toString().isNotEmpty) {
        try {
          await _storage.refFromURL(videoData['thumbnailUrl']).delete();
          print('CourseRepository: Deleted video thumbnail: ${videoData['thumbnailUrl']}');
        } catch (e) {
          print('CourseRepository: Failed to delete thumbnail (may not exist): $e');
          // Continue with deletion even if storage file doesn't exist
        }
      }
      
      // Delete video document from Firestore
      await _firestore.collection('videos').doc(videoId).delete();
      print('CourseRepository: Successfully deleted video document: $videoId');
      
      // Remove video from module's videos array
      await _removeVideoFromModule(courseId, moduleId, videoId);
      
      // Update module total duration
      await updateModuleTotalDuration(courseId, moduleId);
      
      // Trigger user progress sync for all users who have progress for this course
      await _triggerUserProgressSync(courseId);
      
    } catch (e) {
      print('CourseRepository: Error deleting video: $e');
      throw Exception('Failed to delete video: $e');
    }
  }

  // File Upload Operations
  Future<String> uploadThumbnail(String filePath, String fileName, {String? existingUrl}) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('course_thumbnails/$fileName');
      
      // Delete existing file if provided and it's different
      if (existingUrl != null && existingUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingUrl).delete();
          print('CourseRepository: Deleted existing thumbnail: $existingUrl');
        } catch (e) {
          print('CourseRepository: Failed to delete existing thumbnail: $e');
          // Continue with upload even if deletion fails
        }
      }
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('CourseRepository: Uploaded new thumbnail: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }

  Future<String> uploadCertificate(String filePath, String fileName, {String? existingUrl}) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('certificates/$fileName');
      
      // Delete existing file if provided and it's different
      if (existingUrl != null && existingUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingUrl).delete();
          print('CourseRepository: Deleted existing certificate: $existingUrl');
        } catch (e) {
          print('CourseRepository: Failed to delete existing certificate: $e');
          // Continue with upload even if deletion fails
        }
      }
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('CourseRepository: Uploaded new certificate: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload certificate: $e');
    }
  }

  Future<String> uploadVideo(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('videos/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<int> getVideoDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Video file does not exist: $filePath');
        return 300; // Default 5 minutes
      }

      // Get file size and estimate duration
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      
      // More accurate estimation based on common video bitrates and compression
      // Typical video bitrates: 1-5 Mbps for mobile, 5-15 Mbps for HD
      int estimatedDuration;
      
      // Estimate based on file extension and size
      final fileName = filePath.toLowerCase();
      final isHighQuality = fileName.contains('4k') || fileName.contains('1080p') || fileSizeMB > 100;
      final isLowQuality = fileName.contains('480p') || fileName.contains('360p') || fileSizeMB < 5;
      
      if (isLowQuality) {
        // Low quality videos: higher compression ratio
        estimatedDuration = (fileSizeMB * 6).round(); // 6 seconds per MB
      } else if (isHighQuality) {
        // High quality videos: lower compression ratio  
        estimatedDuration = (fileSizeMB * 18).round(); // 18 seconds per MB
      } else {
        // Standard quality videos: balanced compression
        estimatedDuration = (fileSizeMB * 12).round(); // 12 seconds per MB
      }
      
      // Additional adjustment based on file size patterns
      if (fileSizeMB < 2) {
        // Very small files might be highly compressed
        estimatedDuration = (estimatedDuration * 0.7).round();
      } else if (fileSizeMB > 500) {
        // Very large files might be uncompressed or high bitrate
        estimatedDuration = (estimatedDuration * 1.3).round();
      }
      
      // Ensure reasonable bounds
      estimatedDuration = estimatedDuration.clamp(10, 10800); // 10 seconds to 3 hours
      
      print('Video duration estimated: $estimatedDuration seconds (${estimatedDuration ~/ 60}:${(estimatedDuration % 60).toString().padLeft(2, '0')}) for ${fileSizeMB.toStringAsFixed(1)}MB file');
      return estimatedDuration;
      
    } catch (e) {
      print('Error estimating video duration: $e');
      return 300; // Default 5 minutes
    }
  }

  Future<String> uploadVideoThumbnail(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('video_thumbnails/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload video thumbnail: $e');
    }
  }

  // Search and Filter Operations
  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  Future<List<Map<String, dynamic>>> filterCourses(String filter, String sortBy) async {
    try {
      Query query = _firestore.collection('courses');
      
      // Apply filter
      if (filter != 'all') {
        query = query.where('status', isEqualTo: filter);
      }
      
      // Apply sorting
      switch (sortBy) {
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'oldest':
          query = query.orderBy('createdAt', descending: false);
          break;
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        case 'students':
          query = query.orderBy('studentCount', descending: true);
          break;
        case 'title':
          query = query.orderBy('title', descending: false);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter courses: $e');
    }
  }

  // Helper Methods
  Future<void> _deleteCourseModules(String courseId) async {
    final modules = await getCourseModules(courseId);
    
    for (final module in modules) {
      await deleteModule(courseId, module['id']);
    }
  }

  Future<void> _deleteModuleVideos(String courseId, String moduleId) async {
    final videos = await getModuleVideos(courseId, moduleId);
    
    for (final video in videos) {
      await deleteVideo(courseId, moduleId, video['id']);
    }
  }

  // Analytics Methods
  Future<int> getCourseEnrollmentCount(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get enrollment count: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCourseReviews(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// Update course rating based on reviews
  Future<void> updateCourseRating(String courseId, double averageRating, int totalReviews) async {
    try {
      print('CourseRepository: Updating course rating for $courseId');
      print('CourseRepository: Rating value: $averageRating (type: ${averageRating.runtimeType})');
      print('CourseRepository: Total reviews: $totalReviews (type: ${totalReviews.runtimeType})');
      
      // Ensure rating is properly formatted as double
      final formattedRating = averageRating.toDouble();
      print('CourseRepository: Formatted rating: $formattedRating');
      
      await _firestore.collection('courses').doc(courseId).update({
        'rating': formattedRating,
        'totalReviews': totalReviews,
        'ratingUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('CourseRepository: Course rating updated successfully in Firestore');
      
      // Verify the update by reading the document back
      final updatedDoc = await _firestore.collection('courses').doc(courseId).get();
      if (updatedDoc.exists) {
        final data = updatedDoc.data();
        print('CourseRepository: Verified update - Rating: ${data?['rating']}, Reviews: ${data?['totalReviews']}');
      }
    } catch (e) {
      print('CourseRepository: Error updating course rating: $e');
      throw Exception('Failed to update course rating: $e');
    }
  }
}
