import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../di/service_locator.dart';

class UserProfileHandler {
  final UserRepository _userRepository;

  UserProfileHandler({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? sl<UserRepository>();

  /// Update user profile with new data
  Future<UserModel> updateUserProfile({
    required String uid,
    required String name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    File? profileImage,
    String? currentImageUrl,
  }) async {
    try {
      // Get current user profile
      final currentUser = await _userRepository.getUserProfile(uid);
      if (currentUser == null) {
        throw Exception('User profile not found');
      }

      String? newImageUrl = currentImageUrl;

      // Handle profile image update
      if (profileImage != null) {
        // Delete old image if exists
        if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
          await _userRepository.deleteProfileImage(currentUser.profileImageUrl!);
        }
        
        // Upload new image
        newImageUrl = await _userRepository.uploadProfileImage(uid, profileImage);
      }

      // Create updated user model
      final updatedUser = currentUser.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profileImageUrl: newImageUrl,
        updatedAt: DateTime.now(),
      );

      // Update profile in Firestore
      await _userRepository.updateUserProfile(updatedUser);

      return updatedUser;
    } catch (e) {
      print('UserProfileHandler: Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update only profile image
  Future<String> updateProfileImage({
    required String uid,
    required File imageFile,
    String? currentImageUrl,
  }) async {
    try {
      // Delete old image if exists
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _userRepository.deleteProfileImage(currentImageUrl);
      }

      // Upload new image
      final newImageUrl = await _userRepository.uploadProfileImage(uid, imageFile);

      // Update user profile with new image URL
      final currentUser = await _userRepository.getUserProfile(uid);
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          profileImageUrl: newImageUrl,
          updatedAt: DateTime.now(),
        );
        await _userRepository.updateUserProfile(updatedUser);
      }

      return newImageUrl;
    } catch (e) {
      print('UserProfileHandler: Error updating profile image: $e');
      throw Exception('Failed to update profile image: ${e.toString()}');
    }
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    // Basic phone number validation (can be enhanced)
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  /// Validate name format
  bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  /// Get formatted date string
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Parse date from string
  DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  /// Get age from date of birth
  int? getAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    
    return age;
  }

  /// Get gender options
  List<String> getGenderOptions() {
    return ['Male', 'Female', 'Other', 'Prefer not to say'];
  }

  /// Check if user has complete profile
  bool hasCompleteProfile(UserModel user) {
    return user.name.isNotEmpty &&
           user.phoneNumber != null && user.phoneNumber!.isNotEmpty &&
           user.dateOfBirth != null &&
           user.gender != null && user.gender!.isNotEmpty;
  }

  /// Get profile completion percentage
  double getProfileCompletionPercentage(UserModel user) {
    int completedFields = 0;
    int totalFields = 4; // name, phone, dob, gender

    if (user.name.isNotEmpty) completedFields++;
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) completedFields++;
    if (user.dateOfBirth != null) completedFields++;
    if (user.gender != null && user.gender!.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }
}
