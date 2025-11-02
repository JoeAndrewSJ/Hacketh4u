import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/user_profile_handler.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/bloc/user_profile/user_profile_bloc.dart';
import '../../../core/bloc/user_profile/user_profile_event.dart';
import '../../../core/bloc/user_profile/user_profile_state.dart';
import '../../widgets/common/custom_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userProfileHandler = sl<UserProfileHandler>();
  
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  File? _selectedImageFile;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProfileBloc = context.read<UserProfileBloc>();
    if (userProfileBloc.state is UserProfileLoaded) {
      final user = (userProfileBloc.state as UserProfileLoaded).user;
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _selectedDateOfBirth = user.dateOfBirth;
      _selectedGender = user.gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (state is UserProfileUpdated) {
          CustomSnackBar.showSuccess(context, 'Profile updated successfully!');
          Navigator.pop(context);
        } else if (state is UserProfileError) {
          CustomSnackBar.showError(context, state.error);
        }
      },
      builder: (context, state) {
        UserModel? user;
        if (state is UserProfileLoaded) {
          user = state.user;
        } else if (state is UserProfileUpdated) {
          user = state.user;
        }
        
        return Scaffold(
          backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF8F9FA),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(user, isDark),
                      const SizedBox(height: 24),
                      _buildProfileForm(user, isDark),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSaveButton(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isDark) {
    return Container(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      padding: const EdgeInsets.only(top: 40, bottom: 35),
      child: Column(
        children: [
          // Back button row with title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Professional back button - signup style
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: isDark ? Colors.white : const Color(0xFF212529),
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 44), // Balance the back button
              ],
            ),
          ),

          const SizedBox(height: 35),

          // Enhanced profile picture section
          GestureDetector(
            onTap: _pickImage,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring (subtle)
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            isDark
                                ? Colors.grey.shade800.withOpacity(0.3)
                                : const Color(0xFFF5F5F5),
                            isDark
                                ? Colors.grey.shade700.withOpacity(0.2)
                                : const Color(0xFFE8E8E8),
                          ],
                        ),
                      ),
                    ),
                    // Main profile picture container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : const Color(0xFFE0E0E0),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: _selectedImageFile != null
                            ? Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.cover,
                              )
                            : user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                ? Image.network(
                                    user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(user.name),
                                  )
                                : _buildDefaultAvatar(user.name),
                      ),
                    ),
                    // Upload overlay when uploading
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    // Camera badge - professional style
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Change photo text
                Text(
                  'Tap to change photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF6B6B6B),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(UserModel user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (!_userProfileHandler.isValidName(value ?? '')) {
                  return 'Please enter a valid name (at least 2 characters)';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            
            _buildModernTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!_userProfileHandler.isValidPhoneNumber(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            
            _buildModernDatePicker(
              label: 'Date of Birth',
              icon: Icons.cake_outlined,
              value: _selectedDateOfBirth,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            
            _buildModernGenderPicker(
              label: 'Gender',
              icon: Icons.wc_outlined,
              value: _selectedGender,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : const Color(0xFFAAAAAA),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade500 : const Color(0xFF4A4A4A),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: isDark ? AppTheme.surfaceDark : const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDatePicker({
    required String label,
    required IconData icon,
    required DateTime? value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? _userProfileHandler.formatDate(value)
                        : 'Select your date of birth',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                          : (isDark ? Colors.white38 : const Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernGenderPicker({
    required String label,
    required IconData icon,
    required String? value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectGender,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select your gender',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                          : (isDark ? Colors.white38 : const Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 24,
                  color: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveProfile,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final userRepository = sl<UserRepository>();
      final imageFile = await userRepository.pickImage();
      
      if (imageFile != null) {
        setState(() {
          _selectedImageFile = imageFile;
        });
      }
    } catch (e) {
      CustomSnackBar.showError(context, 'Error picking image: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(1900); // Start from 1900
    final lastDate = now; // Allow up to today

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(now.year - 25), // Default to 25 years ago
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  Future<void> _selectGender() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final genderOptions = _userProfileHandler.getGenderOptions();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            ...genderOptions.map((gender) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _selectedGender == gender
                    ? (isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedGender == gender
                      ? (isDark ? Colors.grey.shade600 : const Color(0xFF4A4A4A))
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: _selectedGender == gender ? 2 : 1,
                ),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                  Navigator.pop(context);
                },
                title: Text(
                  gender,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedGender == gender ? FontWeight.w600 : FontWeight.w500,
                    color: _selectedGender == gender
                        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                trailing: _selectedGender == gender
                    ? Icon(
                        Icons.check_circle,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        size: 24,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userProfileBloc = context.read<UserProfileBloc>();
      UserModel? user;
      if (userProfileBloc.state is UserProfileLoaded) {
        user = (userProfileBloc.state as UserProfileLoaded).user;
      } else if (userProfileBloc.state is UserProfileUpdated) {
        user = (userProfileBloc.state as UserProfileUpdated).user;
      }
      
      if (user == null) {
        throw Exception('User not found');
      }

      final nameChanged = _nameController.text.trim() != user.name;
      final phoneChanged = _phoneController.text.trim() != (user.phoneNumber ?? '');
      final dobChanged = _selectedDateOfBirth != user.dateOfBirth;
      final genderChanged = _selectedGender != user.gender;
      final imageChanged = _selectedImageFile != null;

      if (!nameChanged && !phoneChanged && !dobChanged && !genderChanged && !imageChanged) {
        CustomSnackBar.showInfo(context, 'No changes to save');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      await _userProfileHandler.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        profileImage: _selectedImageFile,
        currentImageUrl: user.profileImageUrl,
      );

      // Reload the user profile to get updated data
      userProfileBloc.add(LoadUserProfile(uid: user.uid));

      // Show success message and navigate back
      CustomSnackBar.showSuccess(context, 'Profile updated successfully!');

      // Navigate back to previous screen
      Navigator.pop(context);

    } catch (e) {
      CustomSnackBar.showError(context, 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

// Custom painter for wave effect
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}