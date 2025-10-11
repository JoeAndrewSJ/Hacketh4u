import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  UserRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required ImagePicker imagePicker,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _storage = storage,
        _imagePicker = imagePicker;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  /// Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      // Create reference to the file in Firebase Storage
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // Extract the file path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting profile image: $e');
      // Don't throw error for deletion failures as it might not exist
    }
  }

  /// Pick and crop image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      try {
        // Try to crop the image to square aspect ratio
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Image',
              toolbarColor: const Color(0xFF2E7D32),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              backgroundColor: Colors.black,
              activeControlsWidgetColor: const Color(0xFF2E7D32),
            ),
            IOSUiSettings(
              title: 'Crop Profile Image',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
            ),
          ],
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
        );

        return croppedFile != null ? File(croppedFile.path) : null;
      } catch (cropError) {
        print('Image cropping failed, using original image: $cropError');
        // Fallback: use the original picked image if cropping fails
        return File(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Update profile image with picked file
  Future<String> updateProfileImage(String uid, String? oldImageUrl, File imageFile) async {
    try {
      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProfileImage(oldImageUrl);
      }

      // Upload new image
      final newImageUrl = await uploadProfileImage(uid, imageFile);

      // Update user profile in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'profileImageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newImageUrl;
    } catch (e) {
      print('Error updating profile image: $e');
      throw Exception('Failed to update profile image: ${e.toString()}');
    }
  }

  /// Update profile image (picks image and uploads)
  Future<String> updateProfileImageWithPicker(String uid, String? oldImageUrl) async {
    try {
      // Pick new image
      final imageFile = await pickImage();
      if (imageFile == null) {
        throw Exception('No image selected');
      }

      return await updateProfileImage(uid, oldImageUrl, imageFile);
    } catch (e) {
      print('Error updating profile image with picker: $e');
      throw Exception('Failed to update profile image: ${e.toString()}');
    }
  }

  /// Update user display name in Firebase Auth
  Future<void> updateDisplayName(String name) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
    } catch (e) {
      print('Error updating display name: $e');
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }

  /// Get user's first name initial for avatar
  String getUserInitial(String name) {
    if (name.isEmpty) return 'U';
    return name.trim().split(' ').first[0].toUpperCase();
  }

  /// Check if user has profile image
  bool hasProfileImage(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty;
  }
}
