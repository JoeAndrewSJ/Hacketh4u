import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'firebase_messaging_background.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/router/app_router.dart';
import 'src/data/services/fcm_service.dart';
import 'src/core/bloc/app_settings/app_settings_bloc.dart';
import 'src/core/bloc/app_settings/app_settings_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  // await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize dependencies
  await init();

  // Initialize FCM service
  final fcmService = sl<FCMService>();
  await fcmService.initialize();

  // Initialize App Settings (load once at startup)
  final appSettingsBloc = sl<AppSettingsBloc>();
  appSettingsBloc.add(const LoadAppSettings());

  runApp(const AppRouter());
}
