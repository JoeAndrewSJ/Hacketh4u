import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthGoogleLoginRequested extends AuthEvent {}

class AuthPhoneLoginRequested extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneLoginRequested({
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [phoneNumber];
}

class AuthOtpVerificationRequested extends AuthEvent {
  final String otp;

  const AuthOtpVerificationRequested({
    required this.otp,
  });

  @override
  List<Object> get props => [otp];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phoneNumber;

  const AuthSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [name, email, password, phoneNumber];
}

class AuthGoogleSignupRequested extends AuthEvent {}

class AuthPhoneSignupRequested extends AuthEvent {
  final String phoneNumber;
  final String name;

  const AuthPhoneSignupRequested({
    required this.phoneNumber,
    required this.name,
  });

  @override
  List<Object> get props => [phoneNumber, name];
}

class AuthOtpSignupVerificationRequested extends AuthEvent {
  final String otp;

  const AuthOtpSignupVerificationRequested({
    required this.otp,
  });

  @override
  List<Object> get props => [otp];
}
