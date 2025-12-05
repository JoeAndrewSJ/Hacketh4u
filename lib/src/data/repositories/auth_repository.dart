import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/bloc/auth/auth_state.dart';
import '../../core/utils/phone_utils.dart';
import '../services/fcm_service.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _sharedPreferences;
  final FCMService _fcmService;

  AuthRepository({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
    required GoogleSignIn googleSignIn,
    required SharedPreferences sharedPreferences,
    required FCMService fcmService,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseFirestore = firebaseFirestore,
        _googleSignIn = googleSignIn,
        _sharedPreferences = sharedPreferences,
        _fcmService = fcmService;

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<firebase_auth.User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  Future<firebase_auth.User> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user account is disabled
      await _checkUserAccountStatus(credential.user!.uid);

      return credential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Throw error with code in brackets so FirebaseErrorHandler can parse it
      throw Exception('[${e.code}] ${e.message}');
    } catch (e) {
      throw Exception('[unknown] $e');
    }
  }

  Future<firebase_auth.User> signUpWithEmailAndPassword(
      String name, String email, String password, String phoneNumber) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Update the user's display name
      await user.updateDisplayName(name);

      // Get FCM token with retry mechanism
      final fcmToken = await _fcmService.getTokenWithRetry();

      // Save additional user data to Firestore
      final userData = {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': email.toLowerCase().contains(AppConstants.adminEmailPattern) ? 'admin' : 'user',
        'isEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add FCM token if available
      if (fcmToken != null) {
        userData['fcmToken'] = fcmToken;
        userData['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
      }

      await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userData);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Throw error with code in brackets so FirebaseErrorHandler can parse it
      throw Exception('[${e.code}] ${e.message}');
    } catch (e) {
      throw Exception('[unknown] $e');
    }
  }

  Future<firebase_auth.User> signInWithGoogle() async {
    firebase_auth.User? authenticatedUser;

    try {
      // Check connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('[network-request-failed] No internet connection. Please check your network and try again.');
      }

      // Use the injected GoogleSignIn instance (configured in service_locator.dart)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('[cancelled] Google sign in was cancelled by user');
      }

      // Get authentication tokens from Google
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('[invalid-credential] Failed to get Google authentication tokens. Please try again.');
      }

      // Verify tokens are not empty
      if (googleAuth.accessToken!.isEmpty || googleAuth.idToken!.isEmpty) {
        throw Exception('[invalid-credential] Received empty authentication tokens. Please try again.');
      }

      print('Google Sign-In: Access token received (length: ${googleAuth.accessToken!.length})');
      print('Google Sign-In: ID token received (length: ${googleAuth.idToken!.length})');

      // Create Firebase credential with Google tokens
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('[unknown] Failed to create user account with Google');
      }

      // Store the authenticated user before any additional checks
      authenticatedUser = userCredential.user!;
      print('Google Sign-In: Firebase authentication successful for user: ${authenticatedUser.uid}');

      // Check if user account is disabled
      // If this fails, we still want to return the authenticated user
      try {
        await _checkUserAccountStatus(authenticatedUser.uid);
      } catch (e) {
        // If account is disabled, rethrow the error
        if (e.toString().contains('Account disabled')) {
          rethrow;
        }
        // Otherwise, log the error but continue
        print('Google Sign-In: Warning - Error checking account status: $e');
      }

      return authenticatedUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Google Sign-In: Firebase error - Code: ${e.code}, Message: ${e.message}');

      // If we have an authenticated user despite the error, return it
      if (authenticatedUser != null) {
        print('Google Sign-In: Returning authenticated user despite error');
        return authenticatedUser;
      }

      // Throw error with code in brackets so FirebaseErrorHandler can parse it
      throw Exception('[${e.code}] ${e.message}');
    } catch (e) {
      print('Google Sign-In: Error - ${e.toString()}');

      // If we have an authenticated user despite the error, return it
      if (authenticatedUser != null) {
        print('Google Sign-In: Returning authenticated user despite error');
        return authenticatedUser;
      }

      // Handle specific error patterns
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('sign_in_failed') || errorString.contains('sign-in failed')) {
        throw Exception('[network-request-failed] Google Sign-In failed. Please check your internet connection and try again.');
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        throw Exception('[network-request-failed] Network error occurred. Please check your internet connection.');
      } else if (errorString.contains('platform') || errorString.contains('platformexception')) {
        throw Exception('[internal-error] Platform error occurred. Please try again.');
      } else if (errorString.contains('cancelled')) {
        throw Exception('[cancelled] Google sign in was cancelled.');
      } else if (errorString.contains('pigeonuserdetails') || errorString.contains('type cast')) {
        // This is a known issue with google_sign_in package - if Firebase auth succeeded, ignore this error
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          print('Google Sign-In: Ignoring PigeonUserDetails error, user is authenticated');
          return currentUser;
        }
        throw Exception('[internal-error] Authentication completed but encountered a platform error. Please restart the app.');
      } else {
        // Re-throw if already formatted with error code
        if (e.toString().startsWith('[')) {
          rethrow;
        }
        throw Exception('[unknown] ${e.toString()}');
      }
    }
  }

  Future<String> signInWithPhoneNumber(String phoneNumber) async {
    try {
      // Check connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Format phone number with country code
      final formattedPhoneNumber = PhoneUtils.formatPhoneNumber(phoneNumber);

      final completer = Completer<String>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          // Auto-verification completed
          if (!completer.isCompleted) {
            completer.completeError('Auto-verification not supported in this flow');
          }
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError('Phone verification failed: ${e.message}');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // Code sent successfully
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - still complete with the verification ID
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          throw Exception('Phone verification timeout. Please try again.');
        },
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Throw error with code in brackets so FirebaseErrorHandler can parse it
      throw Exception('[${e.code}] ${e.message}');
    } catch (e) {
      if (e.toString().contains('invalid-phone-number')) {
        throw Exception('[invalid-phone-number] Invalid phone number format.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('[too-many-requests] Too many requests.');
      } else if (e.toString().contains('quota-exceeded')) {
        throw Exception('[quota-exceeded] SMS quota exceeded.');
      } else {
        throw Exception('[unknown] ${e.toString()}');
      }
    }
  }

  Future<firebase_auth.User> verifyOtp(String otp, String verificationId) async {
    firebase_auth.User? authenticatedUser;

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Failed to verify OTP. Please try again.');
      }

      // Store the authenticated user before any additional checks
      authenticatedUser = userCredential.user!;
      print('Phone OTP: Firebase authentication successful for user: ${authenticatedUser.uid}');

      // Check if user account is disabled
      // If this fails, we still want to return the authenticated user
      try {
        await _checkUserAccountStatus(authenticatedUser.uid);
      } catch (e) {
        // If account is disabled, rethrow the error
        if (e.toString().contains('Account disabled')) {
          rethrow;
        }
        // Otherwise, log the error but continue
        print('Phone OTP: Warning - Error checking account status: $e');
      }

      return authenticatedUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Phone OTP: Firebase error - Code: ${e.code}, Message: ${e.message}');

      // If we have an authenticated user despite the error, return it
      if (authenticatedUser != null) {
        print('Phone OTP: Returning authenticated user despite error');
        return authenticatedUser;
      }

      // Throw error with code in brackets so FirebaseErrorHandler can parse it
      throw Exception('[${e.code}] ${e.message}');
    } catch (e) {
      print('Phone OTP: Error - ${e.toString()}');

      // If we have an authenticated user despite the error, return it
      if (authenticatedUser != null) {
        print('Phone OTP: Returning authenticated user despite error');
        return authenticatedUser;
      }

      if (e.toString().contains('invalid-verification-code')) {
        throw Exception('[invalid-verification-code] Invalid OTP.');
      } else if (e.toString().contains('session-expired')) {
        throw Exception('[session-expired] OTP session expired.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('[too-many-requests] Too many attempts.');
      } else {
        throw Exception('[unknown] ${e.toString()}');
      }
    }
  }

  /// ADDED: Create or update user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      print('Creating user profile for UID: $uid, Email: $email');
      
      // Get FCM token with retry mechanism
      final fcmToken = await _fcmService.getTokenWithRetry();
      print('AuthRepository: FCM token for user $uid: ${fcmToken != null ? 'AVAILABLE' : 'NULL'}');
      
      // Check if user profile already exists
      final docSnapshot = await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        // Create new user profile
        final isAdmin = email.toLowerCase().contains(AppConstants.adminEmailPattern);
        final role = isAdmin ? 'admin' : 'user';
        
        print('Creating new user profile with role: $role');

        final userData = {
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role,
          'isEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add FCM token if available
        if (fcmToken != null) {
          userData['fcmToken'] = fcmToken;
          userData['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
        }

        await _firebaseFirestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(userData);

        print('User profile created successfully');

        // Update display name if not set
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser?.displayName == null || currentUser!.displayName!.isEmpty) {
          await currentUser?.updateDisplayName(name);
        }
      } else {
        print('User profile already exists, updating if needed');
        // Update existing profile if fields are missing
        final data = docSnapshot.data();
        final Map<String, dynamic> updates = {};

        if (data?['name'] == null || (data!['name'] as String).isEmpty) {
          updates['name'] = name;
        }
        if (data?['email'] == null || (data?['email'] as String).isEmpty) {
          updates['email'] = email;
        }
        if (data?['phoneNumber'] == null || (data?['phoneNumber'] as String).isEmpty) {
          updates['phoneNumber'] = phoneNumber;
        }

        // Update FCM token if available
        if (fcmToken != null) {
          updates['fcmToken'] = fcmToken;
          updates['fcmTokenUpdatedAt'] = FieldValue.serverTimestamp();
        }

        if (updates.isNotEmpty) {
          await _firebaseFirestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .update(updates);
          print('User profile updated successfully');
        }
      }
    } catch (e) {
      print('Error creating user profile: $e');
      // Don't throw error - user profile creation is not critical for authentication
      // The user role can be determined from email as a fallback
      print('AuthRepository: Continuing despite profile creation error');
    }
  }

  Future<void> signOut() async {
    try {
      // Remove FCM token from user profile before signing out
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _fcmService.removeTokenFromUserProfile(currentUser.uid);
      }
    } catch (e) {
      print('Error removing FCM token during logout: $e');
      // Continue with logout even if FCM token removal fails
    }

    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
    await _sharedPreferences.remove(AppConstants.userRoleKey);
    await _sharedPreferences.remove(AppConstants.userEmailKey);
    await _sharedPreferences.remove(AppConstants.fcmTokenKey);
  }

  Future<UserRole?> getUserRole(String userId) async {
    try {
      // Check if role is cached
      final cachedRole = _sharedPreferences.getString(AppConstants.userRoleKey);
      if (cachedRole != null) {
        return cachedRole == 'admin' ? UserRole.admin : UserRole.user;
      }

      // Try to get from Firestore
      final doc = await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'] as String?;
        final userRole = role == 'admin' ? UserRole.admin : UserRole.user;
        await _sharedPreferences.setString(AppConstants.userRoleKey, role ?? 'user');
        return userRole;
      } else {
        // Return null if no profile exists (new user)
        return null;
      }
    } catch (e) {
      print('AuthRepository: Error getting user role: $e');

      // Fallback to email-based role detection
      try {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          final email = currentUser.email ?? '';
          final isAdmin = email.toLowerCase().contains(AppConstants.adminEmailPattern);
          final userRole = isAdmin ? UserRole.admin : UserRole.user;
          final roleString = isAdmin ? 'admin' : 'user';

          await _sharedPreferences.setString(AppConstants.userRoleKey, roleString);
          await _sharedPreferences.setString(AppConstants.userEmailKey, email);
          return userRole;
        }
      } catch (fallbackError) {
        print('AuthRepository: Fallback role detection failed: $fallbackError');
      }
    }

    return UserRole.user;
  }

  /// Update FCM token for currently logged-in user
  Future<void> updateFCMTokenForCurrentUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        final fcmToken = await _fcmService.getTokenWithRetry();
        if (fcmToken != null) {
          await _fcmService.saveTokenToUserProfile(currentUser.uid, fcmToken);
          print('FCM token updated for current user: ${currentUser.uid}');
        } else {
          print('FCM token still not available for user: ${currentUser.uid}');
        }
      }
    } catch (e) {
      print('Error updating FCM token for current user: $e');
      // Don't throw error as this is not critical for app functionality
    }
  }

  /// Ensure FCM token is saved for current user (call this after successful login)
  Future<void> ensureFCMTokenSaved() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // First try to get the token
        String? fcmToken = await _fcmService.getTokenWithRetry();
        
        if (fcmToken != null) {
          // Token is available, save it
          await _fcmService.saveTokenToUserProfile(currentUser.uid, fcmToken);
          print('FCM token ensured and saved for user: ${currentUser.uid}');
        } else {
          // Token not available, try again after a delay
          print('FCM token not available immediately, will retry later...');
          Future.delayed(const Duration(seconds: 5), () async {
            final retryToken = await _fcmService.getTokenWithRetry();
            if (retryToken != null) {
              await _fcmService.saveTokenToUserProfile(currentUser.uid, retryToken);
              print('FCM token saved on retry for user: ${currentUser.uid}');
            }
          });
        }
      }
    } catch (e) {
      print('Error ensuring FCM token is saved: $e');
    }
  }

  /// Get FCM token for current user
  Future<String?> getFCMTokenForCurrentUser() async {
    try {
      return await _fcmService.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Check if user account is disabled
  Future<void> _checkUserAccountStatus(String userId) async {
    try {
      final doc = await _firebaseFirestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final isEnabled = doc.data()!['isEnabled'] ?? true;
        if (!isEnabled) {
          // Sign out the user if account is disabled
          await signOut();
          throw Exception('Account disabled. Please contact administrator.');
        }
      }
    } catch (e) {
      if (e.toString().contains('Account disabled')) {
        rethrow;
      }
      // If there's an error checking status, allow login to proceed
      print('Error checking user account status: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('AuthRepository: Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('AuthRepository: Password reset email sent successfully');
    } catch (e) {
      print('AuthRepository: Error sending password reset email: $e');
      rethrow;
    }
  }
}