import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/widgets.dart';
import '../../../core/bloc/mentor/mentor_bloc.dart';
import '../../../core/bloc/mentor/mentor_event.dart';
import '../../../core/bloc/mentor/mentor_state.dart';
import '../../widgets/loading/hackethos_loading_component.dart';
import 'mentors_list_screen.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/di/service_locator.dart';

class MentorCreationScreen extends StatefulWidget {
  const MentorCreationScreen({super.key});

  @override
  State<MentorCreationScreen> createState() => _MentorCreationScreenState();
}

class _MentorCreationScreenState extends State<MentorCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _profileImagePath;
  File? _selectedImageFile;
  final List<String> _expertiseTags = [];
  final ImagePicker _imagePicker = ImagePicker();
  final UserRepository _userRepository = sl<UserRepository>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<MentorBloc, MentorState>(
      listener: (context, state) {
        if (state is MentorCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mentor "${state.mentor['name']}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearForm();
          Navigator.of(context).pop();
        } else if (state is MentorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating mentor: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<MentorBloc, MentorState>(
        builder: (context, mentorState) {
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Create Mentor'),
                  backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
                  foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
                  elevation: 0,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MentorsListScreen(),
                        ),
                      ),
                      child: Text(
                        'See All',
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                                  isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add New Mentor',
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create a mentor profile to help students learn',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Profile Image Upload
                          Text(
                            'Profile Image',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildProfileImageUpload(context),
                          const SizedBox(height: 24),
                          
                          // Basic Information
                          Text(
                            'Basic Information',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                           // Name
                           CustomTextField(
                             controller: _nameController,
                             label: 'Full Name',
                             hint: 'Enter mentor\'s full name',
                             prefixIcon: const Icon(Icons.person),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter mentor\'s name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                           // Email
                           CustomTextField(
                             controller: _emailController,
                             label: 'Email Address',
                             hint: 'Enter mentor\'s email',
                             prefixIcon: const Icon(Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email address';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                           // Bio
                           CustomTextField(
                             controller: _bioController,
                             label: 'Bio',
                             hint: 'Tell us about the mentor\'s background and expertise',
                             prefixIcon: const Icon(Icons.info),
                            isTextArea: true,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          
                           // Experience
                           CustomTextField(
                             controller: _experienceController,
                             label: 'Years of Experience',
                             hint: 'Enter years of experience',
                             prefixIcon: const Icon(Icons.work),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Expertise Tags
                          _buildExpertiseTags(context),
                          const SizedBox(height: 16),
                          
                          // Social Media Links
                          Text(
                            'Social Media Links (Optional)',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                           // LinkedIn
                           CustomTextField(
                             controller: _linkedinController,
                             label: 'LinkedIn Profile',
                             hint: 'https://linkedin.com/in/username',
                             prefixIcon: const Icon(Icons.link),
                          ),
                          const SizedBox(height: 12),
                          
                          // Twitter
                          CustomTextField(
                            controller: _twitterController,
                            label: 'Twitter Handle',
                            hint: '@username',
                            prefixIcon: const Icon(Icons.link),
                          ),
                          const SizedBox(height: 12),
                          
                          // Website
                          CustomTextField(
                            controller: _websiteController,
                            label: 'Personal Website',
                            hint: 'https://example.com',
                            prefixIcon: const Icon(Icons.link),
                          ),
                          const SizedBox(height: 32),
                          
                          // Create Mentor Button
                          CustomButton(
                            text: 'Create Mentor',
                            onPressed: _createMentor,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Loading overlay
              if (mentorState.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: HackethosLoadingComponent(
                      message: 'Creating mentor...',
                      size: 80,
                      showImage: true,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileImageUpload(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                    width: 2,
                  ),
                ),
                child: _selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(58),
                        child: Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _profileImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(58),
                            child: Image.asset(
                              _profileImagePath!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 48,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            // Remove button (only show when image is selected)
            if (_selectedImageFile != null || _profileImagePath != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _removeProfileImage,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change photo',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildExpertiseTags(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Areas of Expertise',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        
        // Tags display
        if (_expertiseTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _expertiseTags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _expertiseTags.remove(tag);
                });
              },
              deleteIcon: const Icon(Icons.close, size: 18),
            )).toList(),
          ),
        
        const SizedBox(height: 12),
        
        // Add tag input
        Row(
          children: [
               Expanded(
                 child: CustomTextField(
                   label: 'Add expertise area',
                   hint: 'e.g., React, Python, UI/UX',
                onSubmitted: (value) {
                  if (value != null && value.trim().isNotEmpty && !_expertiseTags.contains(value.trim())) {
                    setState(() {
                      _expertiseTags.add(value.trim());
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Add empty tag to trigger input
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Expertise Area'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter expertise area',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final value = controller.text.trim();
                          if (value.isNotEmpty && !_expertiseTags.contains(value)) {
                            setState(() {
                              _expertiseTags.add(value);
                            });
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  void _pickProfileImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Image Source'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _pickImageFromCamera() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: true);
      
      if (imageFile != null) {
        setState(() {
          _selectedImageFile = imageFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _pickImageFromGallery() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: false);
      
      if (imageFile != null) {
        setState(() {
          _selectedImageFile = imageFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _removeProfileImage() {
    setState(() {
      _selectedImageFile = null;
      _profileImagePath = null;
    });
  }

  void _createMentor() {
    if (_formKey.currentState!.validate()) {
      if (_expertiseTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one area of expertise')),
        );
        return;
      }

      // Prepare mentor data
      final mentorData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'yearsOfExperience': int.tryParse(_experienceController.text) ?? 0,
        'primaryExpertise': _expertiseTags.isNotEmpty ? _expertiseTags.first : '',
        'expertiseTags': _expertiseTags,
        'socialLinks': {
          'linkedin': _linkedinController.text.trim().isNotEmpty ? _linkedinController.text.trim() : null,
          'twitter': _twitterController.text.trim().isNotEmpty ? _twitterController.text.trim() : null,
          'website': _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        },
        'isActive': true,
      };

      // Remove null social links
      (mentorData['socialLinks'] as Map<String, dynamic>).removeWhere((key, value) => value == null);

      // Use BLoC to create mentor with image upload
      context.read<MentorBloc>().add(CreateMentor(
        mentorData: mentorData,
        profileImageFile: _selectedImageFile?.path,
      ));
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _bioController.clear();
    _experienceController.clear();
    _linkedinController.clear();
    _twitterController.clear();
    _websiteController.clear();
    setState(() {
      _selectedImageFile = null;
      _profileImagePath = null;
      _expertiseTags.clear();
    });
  }
}
