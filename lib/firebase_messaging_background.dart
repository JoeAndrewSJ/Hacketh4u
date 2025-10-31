import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level function to handle background messages
/// This function must be a top-level function and not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // You can perform background tasks here
  // Note: This function runs in a separate isolate
  // and cannot access the main app's state or UI
  
  // Example: Log the message data
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}
