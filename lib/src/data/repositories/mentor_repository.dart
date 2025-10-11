import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MentorRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MentorRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Mentor CRUD Operations
  Future<List<Map<String, dynamic>>> getAllMentors() async {
    try {
      // First try the simple query without ordering
      final querySnapshot = await _firestore
          .collection('mentors')
          .where('isActive', isEqualTo: true)
          .get();

      // Sort by createdAt in memory to avoid composite index requirement
      final mentors = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt descending in memory
      mentors.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      print('MentorRepository: Successfully loaded ${mentors.length} mentors');
      return mentors;
    } catch (e) {
      print('MentorRepository: Error loading mentors: $e');
      // Fallback: try without the isActive filter
      try {
        final querySnapshot = await _firestore
            .collection('mentors')
            .get();
            
        final mentors = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        // Filter active mentors and sort in memory
        final activeMentors = mentors.where((m) => m['isActive'] == true).toList();
        activeMentors.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        
        print('MentorRepository: Fallback loaded ${activeMentors.length} active mentors');
        return activeMentors;
      } catch (fallbackError) {
        print('MentorRepository: Fallback also failed: $fallbackError');
        throw Exception('Failed to load mentors: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getMentorById(String mentorId) async {
    try {
      final doc = await _firestore.collection('mentors').doc(mentorId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load mentor: $e');
    }
  }

  Future<Map<String, dynamic>> createMentor(Map<String, dynamic> mentorData) async {
    try {
      // Add timestamps
      mentorData['createdAt'] = FieldValue.serverTimestamp();
      mentorData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Set default values
      mentorData['isActive'] = mentorData['isActive'] ?? true;
      
      // Ensure expertiseTags is a list
      if (mentorData['expertiseTags'] == null) {
        mentorData['expertiseTags'] = [];
      }
      
      final docRef = await _firestore.collection('mentors').add(mentorData);
      
      // Return the created mentor with ID
      final createdMentor = Map<String, dynamic>.from(mentorData);
      createdMentor['id'] = docRef.id;
      return createdMentor;
    } catch (e) {
      throw Exception('Failed to create mentor: $e');
    }
  }

  Future<Map<String, dynamic>> updateMentor(String mentorId, Map<String, dynamic> mentorData) async {
    try {
      mentorData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('mentors').doc(mentorId).update(mentorData);
      
      // Return updated mentor
      final updatedMentor = Map<String, dynamic>.from(mentorData);
      updatedMentor['id'] = mentorId;
      return updatedMentor;
    } catch (e) {
      throw Exception('Failed to update mentor: $e');
    }
  }

  Future<void> deleteMentor(String mentorId) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection('mentors').doc(mentorId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete mentor: $e');
    }
  }

  // File Upload Operations
  Future<String> uploadProfileImage(String filePath, String fileName, {String? existingUrl}) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('mentor_profiles/$fileName');
      
      // Delete existing file if provided and it's different
      if (existingUrl != null && existingUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(existingUrl).delete();
          print('MentorRepository: Deleted existing profile image: $existingUrl');
        } catch (e) {
          print('MentorRepository: Failed to delete existing profile image: $e');
          // Continue with upload even if deletion fails
        }
      }
      
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('MentorRepository: Uploaded new profile image: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Search Operations
  Future<List<Map<String, dynamic>>> searchMentors(String query) async {
    try {
      if (query.isEmpty) {
        return getAllMentors();
      }
      
      // Search by name
      final nameQuery = await _firestore
          .collection('mentors')
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Search by primary expertise
      final expertiseQuery = await _firestore
          .collection('mentors')
          .where('isActive', isEqualTo: true)
          .where('primaryExpertise', isGreaterThanOrEqualTo: query)
          .where('primaryExpertise', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combine results and remove duplicates
      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(nameQuery.docs);
      
      for (final doc in expertiseQuery.docs) {
        if (!allDocs.any((existingDoc) => existingDoc.id == doc.id)) {
          allDocs.add(doc);
        }
      }
      
      return allDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search mentors: $e');
    }
  }

  // Analytics Methods
  Future<int> getMentorCourseCount(String mentorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: mentorId)
          .where('status', isEqualTo: 'published')
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get mentor course count: $e');
    }
  }

  Future<int> getMentorStudentCount(String mentorId) async {
    try {
      // Get all courses by this mentor
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: mentorId)
          .get();
      
      if (coursesSnapshot.docs.isEmpty) {
        return 0;
      }
      
      // Get enrollments for all mentor's courses
      final courseIds = coursesSnapshot.docs.map((doc) => doc.id).toList();
      int totalStudents = 0;
      
      for (final courseId in courseIds) {
        final enrollmentsSnapshot = await _firestore
            .collection('enrollments')
            .where('courseId', isEqualTo: courseId)
            .get();
        
        totalStudents += enrollmentsSnapshot.docs.length;
      }
      
      return totalStudents;
    } catch (e) {
      throw Exception('Failed to get mentor student count: $e');
    }
  }

  Future<double> getMentorAverageRating(String mentorId) async {
    try {
      // Get all courses by this mentor
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('mentorId', isEqualTo: mentorId)
          .where('status', isEqualTo: 'published')
          .get();
      
      if (coursesSnapshot.docs.isEmpty) {
        return 0.0;
      }
      
      // Calculate average rating
      double totalRating = 0.0;
      int courseCount = 0;
      
      for (final doc in coursesSnapshot.docs) {
        final courseData = doc.data();
        final rating = courseData['rating'] ?? 0.0;
        if (rating > 0) {
          totalRating += rating;
          courseCount++;
        }
      }
      
      return courseCount > 0 ? totalRating / courseCount : 0.0;
    } catch (e) {
      throw Exception('Failed to get mentor average rating: $e');
    }
  }

  // Bulk Operations
  Future<void> bulkUpdateMentorStatus(List<String> mentorIds, bool isActive) async {
    try {
      final batch = _firestore.batch();
      
      for (final mentorId in mentorIds) {
        final mentorRef = _firestore.collection('mentors').doc(mentorId);
        batch.update(mentorRef, {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update mentor status: $e');
    }
  }

  // Validation Methods
  Future<bool> isEmailUnique(String email, {String? excludeMentorId}) async {
    try {
      Query query = _firestore
          .collection('mentors')
          .where('email', isEqualTo: email.toLowerCase());
      
      if (excludeMentorId != null) {
        // For updates, exclude the current mentor from the check
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeMentorId);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check email uniqueness: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMentorsByExpertise(String expertise) async {
    try {
      final querySnapshot = await _firestore
          .collection('mentors')
          .where('isActive', isEqualTo: true)
          .where('expertiseTags', arrayContains: expertise)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get mentors by expertise: $e');
    }
  }
}
