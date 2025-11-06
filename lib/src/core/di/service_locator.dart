import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/mentor/mentor_bloc.dart';
import '../bloc/course/course_bloc.dart';
import '../bloc/quiz/quiz_bloc.dart';
import '../bloc/coupon/coupon_bloc.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/payment/payment_bloc.dart';
import '../bloc/course_access/course_access_bloc.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/user_progress/user_progress_bloc.dart';
import '../bloc/user_profile/user_profile_bloc.dart';
import '../bloc/community/community_bloc.dart';
import '../bloc/banner/banner_bloc.dart';
import '../bloc/stats/stats_bloc.dart';
import '../bloc/app_settings/app_settings_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../data/repositories/theme_repository.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/user_progress_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/banner_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/services/course_progress_sync_service.dart';
import '../../data/services/fcm_service.dart';
import '../services/course_access_service.dart';
import '../services/user_profile_handler.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => ImagePicker());

  // Repositories
  sl.registerLazySingleton(() => AuthRepository(
        firebaseAuth: sl(),
        firebaseFirestore: sl(),
        googleSignIn: sl(),
        sharedPreferences: sl(),
        fcmService: sl(),
      ));
  sl.registerLazySingleton(() => ConnectivityRepository(sl()));
  sl.registerLazySingleton(() => ThemeRepository(sl()));
  sl.registerLazySingleton(() => MentorRepository(
        firestore: sl(),
        storage: sl(),
      ));
  sl.registerLazySingleton(() => CourseRepository(
        firestore: sl(),
        storage: sl(),
      ));
  sl.registerLazySingleton(() => CartRepository(
        firestore: sl(),
        auth: sl(),
      ));
  sl.registerLazySingleton(() => UserProgressRepository(
        firestore: sl(),
        auth: sl(),
        courseRepository: sl(),
        quizRepository: sl(),
      ));
  sl.registerLazySingleton(() => PaymentRepository(
        firestore: sl(),
        auth: sl(),
        userProgressRepository: sl(),
        courseRepository: sl(),
      ));
  sl.registerLazySingleton(() => ReviewRepository(
        firestore: sl(),
        auth: sl(),
        courseRepository: sl(),
      ));
  sl.registerLazySingleton(() => QuizRepository(
        firestore: sl(),
        auth: sl(),
      ));
  sl.registerLazySingleton(() => UserRepository(
        firebaseAuth: sl(),
        firestore: sl(),
        storage: sl(),
        imagePicker: sl(),
      ));
  sl.registerLazySingleton(() => CommunityRepository(
        firestore: sl(),
        auth: sl(),
      ));
  sl.registerLazySingleton(() => BannerRepository());
  sl.registerLazySingleton(() => StatsRepository(firestore: sl()));
  sl.registerLazySingleton(() => AppSettingsRepository(firestore: sl()));
  sl.registerLazySingleton(() => CourseProgressSyncService(
        userProgressRepository: sl(),
        auth: sl(),
      ));

  // Services
  sl.registerLazySingleton(() => FCMService(
        firebaseMessaging: sl(),
        firebaseFirestore: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerLazySingleton(() => CourseAccessService(
        firestore: sl(),
        auth: sl(),
      ));
  sl.registerLazySingleton(() => UserProfileHandler());

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => ConnectivityBloc(connectivityRepository: sl()));
  sl.registerSingleton(ThemeBloc(themeRepository: sl()));
  sl.registerFactory(() => MentorBloc(mentorRepository: sl()));
  sl.registerFactory(() => CourseBloc(courseRepository: sl()));
  sl.registerFactory(() => QuizBloc(quizRepository: sl()));
  sl.registerFactory(() => CouponBloc(firestore: sl()));
  sl.registerFactory(() => CartBloc(cartRepository: sl()));
  sl.registerFactory(() => PaymentBloc(paymentRepository: sl()));
  sl.registerFactory(() => CourseAccessBloc(courseAccessService: sl()));
  sl.registerFactory(() => ReviewBloc(reviewRepository: sl()));
  sl.registerFactory(() => UserProgressBloc(userProgressRepository: sl()));
  sl.registerFactory(() => UserProfileBloc(userRepository: sl()));
  sl.registerFactory(() => CommunityBloc(communityRepository: sl()));
  sl.registerFactory(() => BannerBloc(bannerRepository: sl()));
  sl.registerFactory(() => StatsBloc(statsRepository: sl()));
  sl.registerSingleton(AppSettingsBloc(repository: sl()));
}
