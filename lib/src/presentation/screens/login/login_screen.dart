import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_event.dart';
import '../../../core/bloc/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/firebase_error_handler.dart';
import '../../widgets/common/widgets.dart';
import '../signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  late TabController _tabController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppTheme.primaryLight,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
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
          
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFFFF5F5),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Curved Header
                _buildCurvedHeader(context),
                
                // Main Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          
                          // App Logo
                          _buildAppLogo(context),
                          const SizedBox(height: 30),
                          
                          // Tab Bar
                          _buildTabBar(context),
                          const SizedBox(height: 30),
                          
                          // Tab Views
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEmailLoginForm(context),
                                _buildGoogleLoginForm(context),
                                _buildPhoneLoginForm(context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Sign up link
                          _buildSignUpLink(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Welcome Back!',
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue your learning journey',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Column(
      children: [
        
        const SizedBox(height: 16),
        Text(
          'Hackethos4u',
          style: AppTextStyles.h2.copyWith(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your gateway to tech excellence',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF666666),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6C757D),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: const [
          Tab(text: 'Email'),
          Tab(text: 'Google'),
          Tab(text: 'Phone'),
        ],
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF6C757D),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: Text(
            'Sign Up',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              decoration: InputDecoration(
                labelText: 'EMAIL ADDRESS',
                labelStyle: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'example@gmail.com',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            ),
          ),
          const SizedBox(height: 20),
          
          // Password Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              decoration: InputDecoration(
                labelText: 'PASSWORD',
                labelStyle: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                hintText: '••••••••',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF6C757D),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            ),
          ),
          const SizedBox(height: 16),
          
          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember Me',
                    style: TextStyle(
                      color: Color(0xFF6C757D),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _showForgotPasswordDialog(context);
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Sign In Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: state.isAuthLoading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLoginForm(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Google Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipOval(
              child: Image.asset(
                'assets/google.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.g_mobiledata,
                    size: 40,
                    color: Color(0xFF4285F4),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'Sign in with Google',
          style: AppTextStyles.h3.copyWith(
            color: const Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quick and secure access to your account',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF6C757D),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Google Sign In Button
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: state.isAuthLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: state.isAuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/google.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: Color(0xFF4285F4),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneLoginForm(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isPhoneAuth) {
          return _buildOtpForm(context, state);
        }
        
        return Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Phone Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 40,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Sign in with Phone',
                style: AppTextStyles.h3.copyWith(
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send you a verification code',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF6C757D),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Phone Number Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    _PhoneNumberFormatter(),
                  ],
                  style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    labelText: 'PHONE NUMBER',
                    labelStyle: const TextStyle(
                      color: Color(0xFF6C757D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: '12345 67890',
                    hintStyle: const TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 20, top: 18, bottom: 18),
                      child: Text(
                        '+91 ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Remove spaces and check length
                    final cleanNumber = value.replaceAll(' ', '');
                    if (cleanNumber.length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),
              
              // Send OTP Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: state.isAuthLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtpForm(BuildContext context, AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // OTP Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.sms_outlined,
              size: 40,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Enter OTP',
            style: AppTextStyles.h3.copyWith(
              color: const Color(0xFF333333),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${_phoneController.text}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF6C757D),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          
          // OTP Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Color(0xFF333333), fontWeight: FontWeight.w600),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'VERIFICATION CODE',
                labelStyle: const TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                hintText: '000000',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.security,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            ),
          ),
          const SizedBox(height: 30),
          
          // Verify OTP Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(15),
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
                  borderRadius: BorderRadius.circular(15),
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
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Resend OTP
          TextButton(
            onPressed: _resendOtp,
            child: Text(
              'Resend OTP',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _signInWithEmail() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _signInWithGoogle() {
    context.read<AuthBloc>().add(AuthGoogleLoginRequested());
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      // Clean the phone number and add +91 prefix
      final cleanNumber = _phoneController.text.replaceAll(' ', '');
      final fullPhoneNumber = '+91$cleanNumber';
      
      context.read<AuthBloc>().add(
        AuthPhoneLoginRequested(
          phoneNumber: fullPhoneNumber,
        ),
      );
    }
  }

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthOtpVerificationRequested(
          otp: _otpController.text.trim(),
        ),
      );
    }
  }

  void _resendOtp() {
    // Clean the phone number and add +91 prefix
    final cleanNumber = _phoneController.text.replaceAll(' ', '');
    final fullPhoneNumber = '+91$cleanNumber';
    
    context.read<AuthBloc>().add(
      AuthPhoneLoginRequested(
        phoneNumber: fullPhoneNumber,
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authBloc = context.read<AuthBloc>();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.isForgotPasswordSent) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Password reset email sent! Please check your inbox and follow the instructions.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Reset the state
                  authBloc.add(AuthCheckRequested());
                }
                
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(FirebaseErrorHandler.getUserFriendlyMessage(state.errorMessage!)),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 20,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.surfaceDark 
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Forgot Password Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryLight.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/forgotpass.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset,
                                    size: 50,
                                    color: AppTheme.primaryLight,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Title
                        Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.textPrimaryDark 
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          'Don\'t worry! Enter your email address and we\'ll send you a secure link to reset your password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.textSecondaryDark 
                                : AppTheme.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Form
                        Form(
                          key: formKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? AppTheme.textPrimaryDark 
                                    : AppTheme.textPrimaryLight,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email address',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? AppTheme.textSecondaryDark 
                                      : AppTheme.textSecondaryLight,
                                ),
                                labelStyle: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey[600]! 
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey[600]! 
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryLight,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark 
                                    ? AppTheme.surfaceDark 
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryLight,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: state.isAuthLoading ? null : () {
                                  Navigator.of(dialogContext).pop();
                                  emailController.dispose();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? AppTheme.textSecondaryDark 
                                        : AppTheme.textSecondaryLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryLight,
                                      AppTheme.primaryLight.withOpacity(0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryLight.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: state.isAuthLoading ? null : () {
                                    if (formKey.currentState!.validate()) {
                                      authBloc.add(
                                        AuthForgotPasswordRequested(
                                          email: emailController.text.trim(),
                                        ),
                                      );
                                    }
                                  },
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
                                      : const Text(
                                          'Send Reset Link',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digits
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 10 digits
    final limitedText = text.length > 10 ? text.substring(0, 10) : text;
    
    // Format with spaces (5-5 pattern)
    String formattedText = limitedText;
    if (limitedText.length > 5) {
      formattedText = '${limitedText.substring(0, 5)} ${limitedText.substring(5)}';
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
