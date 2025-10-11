import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/banner_model.dart';

class BannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Collection name
  static const String _collection = 'banners';

  // Get all banners
  Future<List<BannerModel>> getBanners() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BannerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('BannerRepository: Error fetching banners: $e');
      throw Exception('Failed to fetch banners: $e');
    }
  }

  // Upload banner image
  Future<String> uploadBannerImage(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'banners/$fileName';

      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('BannerRepository: Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create banner
  Future<BannerModel> createBanner(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload image to storage
      final String fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'banners/$fileName';

      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create banner document
      final DocumentReference docRef = _firestore.collection(_collection).doc();
      final BannerModel banner = BannerModel(
        id: docRef.id,
        createdBy: user.uid,
        imageUrl: downloadUrl,
        imagePath: storagePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(banner.toMap());

      return banner;
    } catch (e) {
      print('BannerRepository: Error creating banner: $e');
      throw Exception('Failed to create banner: $e');
    }
  }

  // Delete banner
  Future<void> deleteBanner(String bannerId, String imagePath) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_collection).doc(bannerId).delete();

      // Delete image from Storage
      try {
        await _storage.ref().child(imagePath).delete();
        print('BannerRepository: Image deleted from storage: $imagePath');
      } catch (storageError) {
        print('BannerRepository: Error deleting image from storage: $storageError');
        // Don't throw here as the Firestore deletion was successful
      }
    } catch (e) {
      print('BannerRepository: Error deleting banner: $e');
      throw Exception('Failed to delete banner: $e');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('BannerRepository: Error picking image: $e');
      return null;
    }
  }

  // Toggle banner active status
  Future<void> toggleBannerStatus(String bannerId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('BannerRepository: Error toggling banner status: $e');
      throw Exception('Failed to toggle banner status: $e');
    }
  }
}
