import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthGoogleLoginRequested>(_onAuthGoogleLoginRequested);
    on<AuthPhoneLoginRequested>(_onAuthPhoneLoginRequested);
    on<AuthOtpVerificationRequested>(_onAuthOtpVerificationRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthGoogleSignupRequested>(_onAuthGoogleSignupRequested);
    on<AuthPhoneSignupRequested>(_onAuthPhoneSignupRequested);
    on<AuthOtpSignupVerificationRequested>(_onAuthOtpSignupVerificationRequested);
  }

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        // FIXED: Check if user profile exists, create if missing
        final existingRole = await _authRepository.getUserRole(user.uid);
        if (existingRole == null) {
          // Create user profile for existing Firebase user
          await _authRepository.createUserProfile(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            phoneNumber: user.phoneNumber ?? '',
          );
        }
        
        final userRole = await _authRepository.getUserRole(user.uid);
        emit(state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isAuthLoading: false,
          user: user,
          userRole: userRole,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      
      // FIXED: Check if user profile exists, create if missing
      final existingRole = await _authRepository.getUserRole(user.uid);
      if (existingRole == null) {
        // Create user profile for existing Firebase user
        await _authRepository.createUserProfile(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
        );
      }
      
      final userRole = await _authRepository.getUserRole(user.uid);
      print('AuthBloc: User authenticated successfully. Role: $userRole');
      
      // Ensure FCM token is saved for the user
      _authRepository.ensureFCMTokenSaved();
      
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthGoogleLoginRequested(
      AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.signInWithGoogle();
      
      // FIXED: Check if user profile exists, create if missing
      final existingRole = await _authRepository.getUserRole(user.uid);
      if (existingRole == null) {
        // Create user profile for existing Firebase user
        await _authRepository.createUserProfile(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
        );
      }
      
      final userRole = await _authRepository.getUserRole(user.uid);
      print('AuthBloc: User authenticated successfully. Role: $userRole');
      
      // Ensure FCM token is saved for the user
      _authRepository.ensureFCMTokenSaved();
      
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthPhoneLoginRequested(
      AuthPhoneLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final verificationId = await _authRepository.signInWithPhoneNumber(
        event.phoneNumber,
      );
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        isPhoneAuth: true,
        verificationId: verificationId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthOtpVerificationRequested(
      AuthOtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.verifyOtp(
        event.otp,
        state.verificationId!,
      );
      
      // FIXED: Check if user profile exists, create if missing (for login flow)
      final existingRole = await _authRepository.getUserRole(user.uid);
      if (existingRole == null) {
        // Create user profile for existing Firebase user
        await _authRepository.createUserProfile(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
        );
      }
      
      final userRole = await _authRepository.getUserRole(user.uid);
      
      // Ensure FCM token is saved for the user
      _authRepository.ensureFCMTokenSaved();
      
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
        isPhoneAuth: false,
        verificationId: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _authRepository.signOut();
      emit(const AuthState(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
      AuthForgotPasswordRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: Forgot password requested for email: ${event.email}');
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      print('AuthBloc: Password reset email sent successfully');
      emit(state.copyWith(
        isAuthLoading: false,
        isForgotPasswordSent: true,
        errorMessage: null,
      ));
    } catch (e) {
      print('AuthBloc: Error in forgot password: $e');
      emit(state.copyWith(
        isAuthLoading: false,
        isForgotPasswordSent: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final userRole = await _authRepository.getUserRole(user.uid);
        emit(state.copyWith(
          isAuthenticated: true,
          user: user,
          userRole: userRole,
        ));
      } else {
        emit(const AuthState());
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAuthSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        event.name,
        event.email,
        event.password,
        event.phoneNumber,
      );
      final userRole = await _authRepository.getUserRole(user.uid);
      print('AuthBloc: User authenticated successfully. Role: $userRole');
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthGoogleSignupRequested(
      AuthGoogleSignupRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.signInWithGoogle();

      // FIXED: Check if user already exists, if not create profile
      final existingRole = await _authRepository.getUserRole(user.uid);

      // If no role exists, this is a new user - create their profile
      if (existingRole == null) {
        // Create user profile with Google display name
        await _authRepository.createUserProfile(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
        );
      }

      final userRole = await _authRepository.getUserRole(user.uid);
      print('AuthBloc: User authenticated successfully. Role: $userRole');
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthPhoneSignupRequested(
      AuthPhoneSignupRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final verificationId = await _authRepository.signInWithPhoneNumber(
        event.phoneNumber,
      );
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        isPhoneAuth: true,
        isSignupMode: true,
        verificationId: verificationId,
        tempName: event.name,
        tempPhoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthOtpSignupVerificationRequested(
      AuthOtpSignupVerificationRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isAuthLoading: true, errorMessage: null));
    try {
      final user = await _authRepository.verifyOtp(
        event.otp,
        state.verificationId!,
      );

      // FIXED: Create user profile if in signup mode
      if (state.isSignupMode) {
        // Check if profile already exists
        final existingRole = await _authRepository.getUserRole(user.uid);

        if (existingRole == null) {
          // Create user profile with stored name and phone
          await _authRepository.createUserProfile(
            uid: user.uid,
            name: state.tempName ?? 'User',
            email: user.email ?? '',
            phoneNumber: state.tempPhoneNumber ?? user.phoneNumber ?? '',
          );
        }
      }

      final userRole = await _authRepository.getUserRole(user.uid);
      emit(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isAuthLoading: false,
        user: user,
        userRole: userRole,
        isPhoneAuth: false,
        isSignupMode: false,
        verificationId: null,
        tempName: null,
        tempPhoneNumber: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isAuthLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}