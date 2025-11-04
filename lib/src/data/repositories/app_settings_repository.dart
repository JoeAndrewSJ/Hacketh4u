import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings_model.dart';

class AppSettingsRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'app_settings';
  static const String _documentId = 'general';

  AppSettingsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Get app settings (one-time read)
  Future<AppSettings> getAppSettings() async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(_documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppSettings.fromJson(doc.data()!);
      } else {
        // If document doesn't exist, create it with default settings
        final defaultSettings = AppSettings.defaultSettings();
        await _firestore
            .collection(_collection)
            .doc(_documentId)
            .set(defaultSettings.toJson());
        return defaultSettings;
      }
    } catch (e) {
      print('AppSettingsRepository: Error fetching settings: $e');
      // Return default settings on error
      return AppSettings.defaultSettings();
    }
  }

  /// Get app settings as a stream (real-time updates)
  Stream<AppSettings> getAppSettingsStream() {
    return _firestore
        .collection(_collection)
        .doc(_documentId)
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
      handleData: (snapshot, sink) {
        print('AppSettingsRepository: Stream received snapshot, exists: ${snapshot.exists}');
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          print('AppSettingsRepository: Raw data from Firestore: $data');
          final settings = AppSettings.fromJson(data);
          print('AppSettingsRepository: Parsed isCommunityEnabled: ${settings.isCommunityEnabled}');
          sink.add(settings);
        } else {
          print('AppSettingsRepository: Document does not exist, using defaults');
          sink.add(AppSettings.defaultSettings());
        }
      },
      handleError: (error, stackTrace, sink) {
        print('AppSettingsRepository: Stream error (likely after logout): $error');
        // Emit default settings on permission or other errors
        sink.add(AppSettings.defaultSettings());
      },
    ));
  }

  /// Update community toggle setting
  Future<void> updateCommunityToggle({
    required bool isEnabled,
    String? adminId,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(_documentId)
          .set({
        'isCommunityEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
      }, SetOptions(merge: true));

      print('AppSettingsRepository: Community toggle updated to $isEnabled');
    } catch (e) {
      print('AppSettingsRepository: Error updating community toggle: $e');
      throw Exception('Failed to update community setting: $e');
    }
  }

  /// Initialize settings document if it doesn't exist
  Future<void> initializeSettings() async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        final defaultSettings = AppSettings.defaultSettings();
        await _firestore
            .collection(_collection)
            .doc(_documentId)
            .set(defaultSettings.toJson());
        print('AppSettingsRepository: Initialized default settings');
      }
    } catch (e) {
      print('AppSettingsRepository: Error initializing settings: $e');
    }
  }
}
