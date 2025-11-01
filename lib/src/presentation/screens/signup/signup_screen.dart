import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_event.dart';
import '../../../core/bloc/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/firebase_error_handler.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _usePhoneSignup = false; // Toggle between email and phone signup
  bool _isPhoneFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(FirebaseErrorHandler.getUserFriendlyMessage(state.errorMessage!)),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
            if (state.isAuthenticated) {
              Navigator.of(context).pop();
            }
          },
          child: SafeArea(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state.isPhoneAuth && _usePhoneSignup) {
                  return _buildOtpForm();
                }
                return _buildSignupForm();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  if (_usePhoneSignup) {
                    // If in phone signup mode, go back to email signup
                    setState(() {
                      _usePhoneSignup = false;
                      _phoneController.clear();
                    });
                  } else {
                    // If in email signup mode, go back to login
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF212529),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sign Up Title
            Text(
              _usePhoneSignup ? 'Sign Up with Phone' : 'Sign Up',
              style: AppTextStyles.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212529),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // Name Field (only show in email mode)
            if (!_usePhoneSignup) ...[
              _buildNameField(),
              const SizedBox(height: 20),
            ],

            // Show either Email/Password or Phone fields
            if (!_usePhoneSignup) ...[
              // Email Field
              _buildEmailField(),
              const SizedBox(height: 20),

              // Password Field
              _buildPasswordField(),
              const SizedBox(height: 20),

              // Confirm Password Field
              _buildConfirmPasswordField(),
            ] else ...[
              // Phone Number Field
              _buildPhoneNumberField(),
            ],
            const SizedBox(height: 30),

            // Sign Up Button
            _buildSignUpButton(),
            const SizedBox(height: 20),

            // Sign In Link
            _buildSignInLink(),
            const SizedBox(height: 30),

            // Continue with Google (only show when in email mode)
            if (!_usePhoneSignup) ...[
              _buildGoogleButton(),
              const SizedBox(height: 16),

              // Sign Up with Phone Number
              _buildPhoneButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF212529),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Verify Title
            Text(
              'Verify Phone Number',
              style: AppTextStyles.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212529),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              'We sent a 6-digit code to +91${_phoneController.text}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF6C757D),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // OTP Field
            _buildOtpField(),
            const SizedBox(height: 30),

            // Verify Button
            _buildVerifyButton(),
            const SizedBox(height: 20),

            // Resend OTP
            Center(
              child: TextButton(
                onPressed: _resendOtp,
                child: Text(
                  'Resend OTP',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Continue with Email & Password
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Color(0xFF6C757D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continue with Email & Password',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF6C757D),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 16,
        color: const Color(0xFF212529),
      ),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: const Color(0xFF6C757D),
        ),
        floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'Enter your full name',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16,
          color: const Color(0xFF9E9E9E),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 16,
        color: const Color(0xFF212529),
      ),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: const Color(0xFF6C757D),
        ),
        floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'Enter your email',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16,
          color: const Color(0xFF9E9E9E),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 16,
        color: const Color(0xFF212529),
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: const Color(0xFF6C757D),
        ),
        floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        hintText: '••••••••••••••',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16,
          color: const Color(0xFF9E9E9E),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF9E9E9E),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 16,
        color: const Color(0xFF212529),
      ),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: const Color(0xFF6C757D),
        ),
        floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        hintText: '••••••••••••••',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16,
          color: const Color(0xFF9E9E9E),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF9E9E9E),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPhoneFocused ? AppTheme.primaryLight : const Color(0xFFE0E0E0),
          width: _isPhoneFocused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Country Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _isPhoneFocused ? AppTheme.primaryLight.withOpacity(0.3) : const Color(0xFFE0E0E0),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+91',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF212529),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: _isPhoneFocused ? AppTheme.primaryLight : const Color(0xFF212529),
                  size: 20,
                ),
              ],
            ),
          ),
          // Phone Number Input
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 16,
                color: const Color(0xFF212529),
              ),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF6C757D),
                ),
                floatingLabelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
                hintText: '1712345678',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField() {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF212529),
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 24,
          color: const Color(0xFF9E9E9E),
          letterSpacing: 8,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the OTP';
        }
        if (value.length != 6) {
          return 'OTP must be 6 digits';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: state.isAuthLoading ? null : (_usePhoneSignup ? _sendOtp : _signUpWithEmail),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isAuthLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sign Up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: state.isAuthLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isAuthLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Verify & Sign Up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF6C757D),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Sign In',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: ElevatedButton(
            onPressed: state.isAuthLoading ? null : _signUpWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/google.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Color(0xFF4285F4),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF212529),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: ElevatedButton(
            onPressed: state.isAuthLoading ? null : () {
              setState(() {
                _usePhoneSignup = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 20,
                  color: Color(0xFF212529),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign Up with Phone Number',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF212529),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _signUpWithEmail() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignupRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: '', // Not required for email signup
        ),
      );
    }
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      final cleanNumber = _phoneController.text.trim();
      final fullPhoneNumber = '+91$cleanNumber';

      context.read<AuthBloc>().add(
        AuthPhoneSignupRequested(
          phoneNumber: fullPhoneNumber,
          name: _nameController.text.trim(),
        ),
      );
    }
  }

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthOtpSignupVerificationRequested(
          otp: _otpController.text.trim(),
        ),
      );
    }
  }

  void _resendOtp() {
    final cleanNumber = _phoneController.text.trim();
    final fullPhoneNumber = '+91$cleanNumber';

    context.read<AuthBloc>().add(
      AuthPhoneSignupRequested(
        phoneNumber: fullPhoneNumber,
        name: _nameController.text.trim(),
      ),
    );
  }

  void _signUpWithGoogle() {
    context.read<AuthBloc>().add(AuthGoogleSignupRequested());
  }
}
