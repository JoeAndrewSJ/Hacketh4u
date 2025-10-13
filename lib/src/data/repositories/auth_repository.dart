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
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Check if user account is disabled
    await _checkUserAccountStatus(credential.user!.uid);
    
    return credential.user!;
  }

  Future<firebase_auth.User> signUpWithEmailAndPassword(
      String name, String email, String password, String phoneNumber) async {
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
  }

  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Check connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Configure Google Sign-In for web compatibility
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Failed to create user account with Google');
      }

      // Check if user account is disabled
      await _checkUserAccountStatus(userCredential.user!.uid);

      return userCredential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('An account already exists with this email address.');
        case 'invalid-credential':
          throw Exception('Invalid credentials. Please try again.');
        case 'operation-not-allowed':
          throw Exception('Google Sign-In is not enabled. Please contact support.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        default:
          throw Exception('Google Sign-In failed: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google Sign-In failed. Please check your internet connection and try again.');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('platform_exception')) {
        throw Exception('Platform error. Please restart the app and try again.');
      } else {
        throw Exception('Google Sign-In failed: ${e.toString()}');
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
      switch (e.code) {
        case 'invalid-phone-number':
          throw Exception('Invalid phone number format. Please enter a valid phone number with country code (e.g., +1234567890).');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        case 'quota-exceeded':
          throw Exception('SMS quota exceeded. Please try again later.');
        case 'missing-phone-number':
          throw Exception('Phone number is required.');
        case 'invalid-verification-code':
          throw Exception('Invalid verification code.');
        default:
          throw Exception('Phone verification failed: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('invalid-phone-number')) {
        throw Exception('Invalid phone number format. Please enter a valid phone number with country code (e.g., +1234567890).');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many requests. Please try again later.');
      } else if (e.toString().contains('quota-exceeded')) {
        throw Exception('SMS quota exceeded. Please try again later.');
      } else {
        throw Exception('Phone verification failed: ${e.toString()}');
      }
    }
  }

  Future<firebase_auth.User> verifyOtp(String otp, String verificationId) async {
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

      // Check if user account is disabled
      await _checkUserAccountStatus(userCredential.user!.uid);

      return userCredential.user!;
    } catch (e) {
      if (e.toString().contains('invalid-verification-code')) {
        throw Exception('Invalid OTP. Please check and try again.');
      } else if (e.toString().contains('session-expired')) {
        throw Exception('OTP session expired. Please request a new OTP.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many attempts. Please try again later.');
      } else {
        throw Exception('OTP verification failed: ${e.toString()}');
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
      throw Exception('Failed to create user profile: ${e.toString()}');
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
    // Check if role is cached
    final cachedRole = _sharedPreferences.getString(AppConstants.userRoleKey);
    if (cachedRole != null) {
      return cachedRole == 'admin' ? UserRole.admin : UserRole.user;
    }

    try {
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
      // Fallback to email-based role detection
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