import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum UserRole { user, admin }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isAuthLoading;
  final String? errorMessage;
  final firebase_auth.User? user;
  final UserRole? userRole;
  final bool isPhoneAuth;
  final String? verificationId;
  final bool isSignupMode;
  final String? tempName;
  final String? tempPhoneNumber;
  final bool isForgotPasswordSent;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.isAuthLoading = false,
    this.errorMessage,
    this.user,
    this.userRole,
    this.isPhoneAuth = false,
    this.verificationId,
    this.isSignupMode = false,
    this.tempName,
    this.tempPhoneNumber,
    this.isForgotPasswordSent = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isAuthLoading,
    Object? errorMessage = const _Undefined(),
    firebase_auth.User? user,
    Object? userRole = const _Undefined(),
    bool? isPhoneAuth,
    Object? verificationId = const _Undefined(),
    bool? isSignupMode,
    Object? tempName = const _Undefined(),
    Object? tempPhoneNumber = const _Undefined(),
    bool? isForgotPasswordSent,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isAuthLoading: isAuthLoading ?? this.isAuthLoading,
      errorMessage: errorMessage is _Undefined ? this.errorMessage : errorMessage as String?,
      user: user ?? this.user,
      userRole: userRole is _Undefined ? this.userRole : userRole as UserRole?,
      isPhoneAuth: isPhoneAuth ?? this.isPhoneAuth,
      verificationId: verificationId is _Undefined ? this.verificationId : verificationId as String?,
      isSignupMode: isSignupMode ?? this.isSignupMode,
      tempName: tempName is _Undefined ? this.tempName : tempName as String?,
      tempPhoneNumber: tempPhoneNumber is _Undefined ? this.tempPhoneNumber : tempPhoneNumber as String?,
      isForgotPasswordSent: isForgotPasswordSent ?? this.isForgotPasswordSent,
    );
  }

  @override
  List<Object?> get props => [
        isAuthenticated,
        isLoading,
        isAuthLoading,
        errorMessage,
        user,
        userRole,
        isPhoneAuth,
        verificationId,
    isSignupMode,
    tempName,
    tempPhoneNumber,
    isForgotPasswordSent,
      ];
}

// Helper class to distinguish between null and undefined in copyWith
class _Undefined {
  const _Undefined();
}
