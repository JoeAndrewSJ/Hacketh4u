import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_event.dart';
import '../../../core/bloc/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  late TabController _tabController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                  content: Text(state.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            if (state.isAuthenticated) {
              // Navigate back to login or home based on your flow
              Navigator.of(context).pop();
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
                            const SizedBox(height: 10),
                            
                            
                            
                            // Tab Bar
                            _buildTabBar(context),
                            const SizedBox(height: 30),
                            
                            // Tab Views
                            SizedBox(
                              height: 500,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildEmailSignupForm(context),
                                  _buildGoogleSignupForm(context),
                                  _buildPhoneSignupForm(context),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Sign in link
                            _buildSignInLink(context),
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
            // Back button
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Create Account!',
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            
          ],
        ),
      ),
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

  Widget _buildSignInLink(BuildContext context) {
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
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSignupForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
          CustomTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            keyboardType: TextInputType.name,
            prefixIcon: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 16),
          
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter phone number (e.g., +1234567890)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Check for country code
                  if (!value.startsWith('+')) {
                    return 'Please include country code (e.g., +1234567890)';
                  }
                  if (value.length < 12) {
                    return 'Phone number too short. Include country code';
                  }
                  return null;
                },
              ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
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
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Confirm Password',
            hint: 'Confirm your password',
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
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
          ),
          const SizedBox(height: 24),
          
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Create Account',
                onPressed: state.isAuthLoading ? null : _signUpWithEmail,
                isLoading: state.isAuthLoading,
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignupForm(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.person_add,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Sign up with Google',
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quick and secure account creation',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return CustomButton(
              text: 'Continue with Google',
              onPressed: state.isAuthLoading ? null : _signUpWithGoogle,
              isLoading: state.isAuthLoading,
              icon: const Icon(Icons.g_mobiledata, size: 24),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneSignupForm(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isPhoneAuth) {
          return _buildOtpForm(context, state);
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                keyboardType: TextInputType.name,
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter phone number (e.g., +1234567890)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Check for country code
                  if (!value.startsWith('+')) {
                    return 'Please include country code (e.g., +1234567890)';
                  }
                  if (value.length < 12) {
                    return 'Phone number too short. Include country code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                text: 'Send OTP',
                onPressed: state.isAuthLoading ? null : _sendOtp,
                isLoading: state.isAuthLoading,
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpForm(BuildContext context, AuthState state) {
    final _otpController = TextEditingController();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
          Icon(
            Icons.sms_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Verify Phone Number',
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${_phoneController.text}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          CustomTextField(
            label: 'OTP',
            hint: 'Enter 6-digit code',
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            prefixIcon: Icon(
              Icons.security,
              color: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 24),
          
          CustomButton(
            text: 'Verify & Create Account',
            onPressed: state.isAuthLoading ? null : () => _verifyOtp(_otpController.text),
            isLoading: state.isAuthLoading,
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _resendOtp,
            child: Text(
              'Resend OTP',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _signUpWithEmail() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthSignupRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
        ),
      );
    }
  }

  void _signUpWithGoogle() {
    context.read<AuthBloc>().add(AuthGoogleSignupRequested());
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthPhoneSignupRequested(
          phoneNumber: _phoneController.text.trim(),
          name: _nameController.text.trim(),
        ),
      );
    }
  }

  void _verifyOtp(String otp) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthOtpSignupVerificationRequested(
          otp: otp,
        ),
      );
    }
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(
      AuthPhoneSignupRequested(
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
      ),
    );
  }
}
