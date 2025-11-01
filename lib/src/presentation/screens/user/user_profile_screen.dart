import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/theme/theme_bloc.dart';
import '../../../core/bloc/theme/theme_event.dart';
import '../../../core/bloc/theme/theme_state.dart';
import '../../../core/bloc/auth/auth_bloc.dart';
import '../../../core/bloc/auth/auth_event.dart';
import '../../../core/bloc/user_profile/user_profile_bloc.dart';
import '../../../core/bloc/user_profile/user_profile_event.dart';
import '../../../core/bloc/user_profile/user_profile_state.dart';
import '../../../data/models/user_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/user_repository.dart';
import '../../widgets/common/logout_dialog.dart';
import 'cart_screen.dart';
import 'my_purchases_screen.dart';
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isUploading = false;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<UserProfileBloc>().add(LoadUserProfile(uid: user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<UserProfileBloc, UserProfileState>(
          listener: (context, state) {
            if (state is UserProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileImageUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile image updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is UserProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            if (state is UserProfileLoaded) {
              return _buildProfileContent(context, state.user, isDark);
            }

            // Fallback for initial state or error
            return _buildProfileContent(context, null, isDark);
          },
        ),
      );
  }

  Widget _buildProfileContent(BuildContext context, UserModel? user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header Card
          _buildProfileHeader(context, user, isDark),
          
          const SizedBox(height: 32),
          
          // Settings Section
          Expanded(
            child: _buildSettingsSection(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel? user, bool isDark) {
    final userName = user?.name ?? 'User Profile';
    final userEmail = user?.email ?? 'user@example.com';
    final profileImageUrl = user?.profileImageUrl;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    final userInitial = _getUserInitial(userName);

    return GestureDetector(
      onTap: () => _navigateToEditProfile(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
          // Profile Avatar with Badge
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePicker(context, user),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: _isUploading
                      ? _buildUploadingAvatar()
                      : _selectedImageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImageFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : hasProfileImage
                              ? ClipOval(
                                  child: Image.network(
                                    profileImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildAvatarWithInitial(userInitial);
                                    },
                                  ),
                                )
                              : _buildAvatarWithInitial(userInitial),
                ),
              ),
              // Edit Badge or Uploading Indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.orange : AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          
          // Trailing Arrow
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAvatarWithInitial(String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getUserInitial(String name) {
    if (name.isEmpty) return 'U';
    return name.trim().split(' ').first[0].toUpperCase();
  }

  Widget _buildSettingsSection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Theme Toggle
          
          
          // Your Cart
          _buildSettingsItem(
            context: context,
            isDark: isDark,
            icon: Icons.shopping_cart,
            title: 'Your Cart',
            subtitle: 'View your cart items',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
          
          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // My Purchases
          _buildSettingsItem(
            context: context,
            isDark: isDark,
            icon: Icons.shopping_bag,
            title: 'My Purchases',
            subtitle: 'View your course purchases',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPurchasesScreen(),
                ),
              );
            },
          ),

          
          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
          _buildSettingsItem(
            context: context,
            isDark: isDark,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Toggle between light and dark theme',
            trailing: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return Switch(
                  value: state.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeBloc>().add(ThemeToggled());
                  },
                  activeColor: AppTheme.primaryLight,
                );
              },
            ),
            onTap: () {
              context.read<ThemeBloc>().add(ThemeToggled());
            },
          ),
          
          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Logout
          _buildSettingsItem(
            context: context,
            isDark: isDark,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryLight,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Trailing Widget
            trailing,
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    LogoutDialog.show(context);
  }

  void _showImagePicker(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(context, user, fromCamera: true);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImagePickerOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _updateProfileImage(context, user, fromCamera: false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProfileImage(BuildContext context, UserModel? user, {bool fromCamera = false}) async {
    if (user == null) return;

    // Check if widget is still mounted
    if (!mounted) return;

    // Store references before async operations
    final userProfileBloc = context.read<UserProfileBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final userRepository = sl<UserRepository>();
      
      // Pick image
      final imageFile = await userRepository.pickImage(fromCamera: fromCamera);
      if (imageFile == null) return;

      // Check if widget is still mounted after image picking
      if (!mounted) return;

      // Show selected image immediately
      setState(() {
        _selectedImageFile = imageFile;
        _isUploading = true;
      });

      // Upload new image
      final newImageUrl = await userRepository.updateProfileImage(
        user.uid,
        user.profileImageUrl,
        imageFile,
      );

      // Check if widget is still mounted after upload
      if (!mounted) return;

      // Update profile in BLoC directly (no need for post frame callback)
      userProfileBloc.add(UpdateProfileImageUrl(
        uid: user.uid,
        newImageUrl: newImageUrl,
      ));

      // Clear uploading state and selected image
      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedImageFile = null;
        });
      }

    } catch (e) {
      print('Profile image update error: $e');
      
      // Check if widget is still mounted
      if (!mounted) return;
      
      // Clear uploading state on error
      setState(() {
        _isUploading = false;
        _selectedImageFile = null;
      });
      
      // Show error message using stored scaffold messenger
      try {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error updating profile image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (scaffoldError) {
        print('Error showing snackbar: $scaffoldError');
      }
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  Widget _buildUploadingAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
