import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/theme/theme_bloc.dart';
import '../../../core/bloc/theme/theme_event.dart';
import '../../../core/bloc/theme/theme_state.dart';
import '../../../core/bloc/user_profile/user_profile_bloc.dart';
import '../../../core/bloc/user_profile/user_profile_event.dart';
import '../../../core/bloc/user_profile/user_profile_state.dart';
import '../../../data/models/user_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/logout_dialog.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'cart_screen.dart';
import 'my_purchases_screen.dart';
import 'edit_profile_screen.dart';
import 'faq_help_screen.dart';

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
              CustomSnackBar.showError(context, state.error);
            } else if (state is ProfileImageUpdated) {
              CustomSnackBar.showSuccess(context, 'Profile image updated successfully!');
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : const Color(0xFFE8E8E8),
                      width: 2,
                    ),
                  ),
                  child: _isUploading
                      ? _buildUploadingAvatar()
                      : _selectedImageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImageFile!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                          : hasProfileImage
                              ? ClipOval(
                                  child: Image.network(
                                    profileImageUrl,
                                    width: 72,
                                    height: 72,
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
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _isUploading
                        ? const Color(0xFF666666)
                        : const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Trailing Arrow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAvatarWithInitial(String initial) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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

          // Help & Support
          _buildSettingsItem(
            context: context,
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs and contact information',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaqHelpScreen(),
                ),
              );
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            // Icon - neutral colors only
            Icon(
              icon,
              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF4A4A4A),
              size: 22,
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
                      color: isDark ? AppTheme.textPrimaryDark : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : const Color(0xFF6B6B6B),
                      fontSize: 12,
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
    final hasProfileImage = user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty;

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

            // Show remove option only if user has a profile image
            if (hasProfileImage) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildImagePickerOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Picture',
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveConfirmation(context, user);
                  },
                  isDestructive: true,
                ),
              ),
            ],

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
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFFF5F5) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive ? const Color(0xFFFFCDD2) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFF44336) : const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? const Color(0xFFC62828) : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 28),
            SizedBox(width: 12),
            Text('Remove Profile Picture'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove your profile picture? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeProfileImage(context, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeProfileImage(BuildContext context, UserModel? user) async {
    if (user == null) return;

    // Check if widget is still mounted
    if (!mounted) return;

    // Store references before async operations
    final userProfileBloc = context.read<UserProfileBloc>();

    try {
      final userRepository = sl<UserRepository>();
      final firestore = FirebaseFirestore.instance;

      // Show loading state
      setState(() {
        _isUploading = true;
        _selectedImageFile = null;
      });

      // Delete the profile image from storage if it exists
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        await userRepository.deleteProfileImage(user.profileImageUrl!);
      }

      // Update profile in Firestore to remove image URL
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'profileImageUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if widget is still mounted
      if (!mounted) return;

      // Update profile in BLoC
      userProfileBloc.add(UpdateProfileImageUrl(
        uid: user.uid,
        newImageUrl: '',
      ));

      // Clear loading state
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      // Show success message
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Profile picture removed successfully');
      }
    } catch (e) {
      print('Profile image removal error: $e');

      // Check if widget is still mounted
      if (!mounted) return;

      // Clear loading state on error
      setState(() {
        _isUploading = false;
      });

      // Show error message
      try {
        CustomSnackBar.showError(context, 'Error removing profile picture: ${e.toString()}');
      } catch (scaffoldError) {
        print('Error showing snackbar: $scaffoldError');
      }
    }
  }

  void _updateProfileImage(BuildContext context, UserModel? user, {bool fromCamera = false}) async {
    if (user == null) return;

    // Check if widget is still mounted
    if (!mounted) return;

    // Store references before async operations
    final userProfileBloc = context.read<UserProfileBloc>();

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
        CustomSnackBar.showError(context, 'Error updating profile image: ${e.toString()}');
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A1A1A),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
