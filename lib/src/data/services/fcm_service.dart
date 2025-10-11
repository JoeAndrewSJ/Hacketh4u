import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firebaseFirestore;
  final SharedPreferences _sharedPreferences;

  FCMService({
    required FirebaseMessaging firebaseMessaging,
    required FirebaseFirestore firebaseFirestore,
    required SharedPreferences sharedPreferences,
  })  : _firebaseMessaging = firebaseMessaging,
        _firebaseFirestore = firebaseFirestore,
        _sharedPreferences = sharedPreferences;

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('FCM Token retrieved: ${token != null ? 'SUCCESS' : 'NULL'}');
      if (token != null) {
        print('FCM Token length: ${token.length}');
      }
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user profile in Firestore
  Future<void> saveTokenToUserProfile(String userId, String token) async {
    try {
      print('Saving FCM token for user: $userId');
      
      await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Also save to local storage for quick access
      await _sharedPreferences.setString(AppConstants.fcmTokenKey, token);
      
      print('FCM token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
      throw Exception('Failed to save FCM token: ${e.toString()}');
    }
  }

  /// Remove FCM token from user profile in Firestore
  Future<void> removeTokenFromUserProfile(String userId) async {
    try {
      print('Removing FCM token for user: $userId');
      
      await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Also remove from local storage
      await _sharedPreferences.remove(AppConstants.fcmTokenKey);
      
      print('FCM token removed successfully');
    } catch (e) {
      print('Error removing FCM token: $e');
      throw Exception('Failed to remove FCM token: ${e.toString()}');
    }
  }

  /// Initialize FCM and request permission
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM permission status: ${settings.authorizationStatus}');

      // Get initial token after permission
      final initialToken = await getToken();
      if (initialToken != null) {
        await _sharedPreferences.setString(AppConstants.fcmTokenKey, initialToken);
        print('Initial FCM token saved to local storage');
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM token refreshed: $newToken');
        _sharedPreferences.setString(AppConstants.fcmTokenKey, newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message: ${message.messageId}');
        // Handle foreground message here
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message opened app: ${message.messageId}');
        // Handle message that opened the app here
      });

    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Get FCM token with retry mechanism
  Future<String?> getTokenWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM Token retrieved on attempt ${i + 1}: SUCCESS');
          return token;
        }
        
        if (i < maxRetries - 1) {
          print('FCM Token is null, retrying in 1 second... (attempt ${i + 1}/$maxRetries)');
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print('Error getting FCM token on attempt ${i + 1}: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    print('Failed to get FCM token after $maxRetries attempts');
    return null;
  }

  /// Get stored FCM token from local storage
  String? getStoredToken() {
    return _sharedPreferences.getString(AppConstants.fcmTokenKey);
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Refresh FCM token for current user
  Future<void> refreshTokenForCurrentUser(String userId) async {
    try {
      final newToken = await getToken();
      if (newToken != null) {
        await saveTokenToUserProfile(userId, newToken);
        print('FCM token refreshed successfully for user: $userId');
      }
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }

  /// Check if FCM token has changed and update if needed
  Future<void> checkAndUpdateTokenIfChanged(String userId) async {
    try {
      final currentToken = await getToken();
      final storedToken = getStoredToken();
      
      if (currentToken != null && currentToken != storedToken) {
        await saveTokenToUserProfile(userId, currentToken);
        print('FCM token updated due to change for user: $userId');
      }
    } catch (e) {
      print('Error checking FCM token: $e');
    }
  }

  /// Force request FCM token and permissions (can be called from UI)
  Future<String?> forceGetToken() async {
    try {
      // Request permission again
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM permission status after force request: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await getTokenWithRetry(maxRetries: 5);
        if (token != null) {
          await _sharedPreferences.setString(AppConstants.fcmTokenKey, token);
          print('FCM token forced and saved: SUCCESS');
        }
        return token;
      } else {
        print('FCM permission not granted, cannot get token');
        return null;
      }
    } catch (e) {
      print('Error forcing FCM token: $e');
      return null;
    }
  }
}
