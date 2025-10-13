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
    String? errorMessage,
    firebase_auth.User? user,
    UserRole? userRole,
    bool? isPhoneAuth,
    String? verificationId,
    bool? isSignupMode,
    String? tempName,
    String? tempPhoneNumber,
    bool? isForgotPasswordSent,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isAuthLoading: isAuthLoading ?? this.isAuthLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      userRole: userRole ?? this.userRole,
      isPhoneAuth: isPhoneAuth ?? this.isPhoneAuth,
      verificationId: verificationId ?? this.verificationId,
      isSignupMode: isSignupMode ?? this.isSignupMode,
      tempName: tempName ?? this.tempName,
      tempPhoneNumber: tempPhoneNumber ?? this.tempPhoneNumber,
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
