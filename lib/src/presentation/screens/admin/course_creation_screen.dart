import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/mentor/mentor_dropdown.dart';
import '../../widgets/navigation/admin_bottom_nav_bar.dart';
import '../home/admin_home_screen.dart';
import '../../../core/bloc/mentor/mentor_bloc.dart';
import '../../../core/bloc/mentor/mentor_event.dart';
import '../../../core/bloc/mentor/mentor_state.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../widgets/loading/hackethos_loading_component.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/di/service_locator.dart';

class CourseCreationScreen extends StatefulWidget {
  final Map<String, dynamic>? courseToEdit;
  
  const CourseCreationScreen({
    super.key,
    this.courseToEdit,
  });

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Edit mode properties
  bool get isEditMode => widget.courseToEdit != null;
  String get screenTitle => isEditMode ? 'Edit Course' : 'Create Course';
  String get submitButtonText => isEditMode ? 'Update Course' : 'Create Course';

  // Step 1 - Basic Information
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _thumbnailPath;
  File? _selectedThumbnailFile;
  final ImagePicker _imagePicker = ImagePicker();
  final UserRepository _userRepository = sl<UserRepository>();

  // Step 2 - Configuration
  String? _selectedMentorId;
  double _completionPercentage = 80.0;
  bool _isCertificateCourse = false;
  String? _certificateImagePath;
  File? _selectedCertificateFile;
  String _certificateAvailability = 'after_review';

  // Certificate field positions (x, y)
  double? _namePositionX;
  double? _namePositionY;
  double? _issueDatePositionX;
  double? _issueDatePositionY;
  double? _certificateNumberPositionX;
  double? _certificateNumberPositionY;

  // Certificate starting number
  final _certificateStartingNumberController = TextEditingController(text: '1000');
  
  // Price Configuration
  bool _isPriceStrikeEnabled = false;
  final _priceController = TextEditingController();
  final _strikePriceController = TextEditingController();
  
  // Subscription Period
  final _subscriptionPeriodController = TextEditingController();

  // Enable/Disable Course
  bool _isEnabled = true;

  // Category Configuration
  String? _selectedCategory;
  final _customCategoryController = TextEditingController();
  final List<String> _predefinedCategories = ['AR VR', 'Cybersecurity'];

  // Mentors will be loaded from BLoC
  List<Mentor> _mentors = [];

  // Step 3 - Curriculum
  final _curriculumController = TextEditingController();
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    // Load mentors when screen initializes
    context.read<MentorBloc>().add(const LoadMentors());
    
    // Initialize form with existing course data if in edit mode
    if (isEditMode && widget.courseToEdit != null) {
      _initializeFormWithExistingData();
    }
  }
  
  void _initializeFormWithExistingData() {
    final course = widget.courseToEdit!;

    // Step 1 - Basic Information
    _courseNameController.text = course['title'] ?? '';
    _descriptionController.text = course['description'] ?? '';
    _thumbnailPath = course['thumbnailUrl'];

    // Step 2 - Configuration
    _selectedMentorId = course['mentorId'];
    _completionPercentage = (course['completionPercentage'] ?? 80.0).toDouble();
    _isCertificateCourse = course['isCertificateCourse'] ?? false;
    _certificateAvailability = course['certificateAvailability'] ?? 'admin_review';
    _certificateImagePath = course['certificateTemplateUrl'];

    // Certificate field positions
    _namePositionX = course['namePositionX']?.toDouble();
    _namePositionY = course['namePositionY']?.toDouble();
    _issueDatePositionX = course['issueDatePositionX']?.toDouble();
    _issueDatePositionY = course['issueDatePositionY']?.toDouble();
    _certificateNumberPositionX = course['certificateNumberPositionX']?.toDouble();
    _certificateNumberPositionY = course['certificateNumberPositionY']?.toDouble();
    _certificateStartingNumberController.text = course['certificateStartingNumber']?.toString() ?? '1000';
    
    // Price Configuration
    _isPriceStrikeEnabled = course['isPriceStrikeEnabled'] ?? false;
    _priceController.text = course['price']?.toString() ?? '';
    _strikePriceController.text = course['strikePrice']?.toString() ?? '';
    
    // Subscription Period
    _subscriptionPeriodController.text = course['subscriptionPeriod']?.toString() ?? '0';

    // Enable/Disable Course
    _isEnabled = course['isPublished'] ?? true;

    // Category Configuration
    final category = course['category'];
    if (category != null && category.isNotEmpty) {
      if (_predefinedCategories.contains(category)) {
        _selectedCategory = category;
      } else {
        _selectedCategory = 'Custom';
        _customCategoryController.text = category;
      }
    }

    // Step 3 - Curriculum
    _curriculumController.text = course['curriculum'] ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _courseNameController.dispose();
    _descriptionController.dispose();
    _curriculumController.dispose();
    _priceController.dispose();
    _strikePriceController.dispose();
    _subscriptionPeriodController.dispose();
    _customCategoryController.dispose();
    _certificateStartingNumberController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a URL (starts with http) or a local file path
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 48,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } else {
      // Local asset path
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 48,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MultiBlocListener(
      listeners: [
        BlocListener<MentorBloc, MentorState>(
          listener: (context, mentorState) {
            // Update mentors list whenever mentor state changes
            if (mentorState.mentors.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _mentors = mentorState.mentors.map((mentorData) => Mentor(
                      id: mentorData['id'] ?? '',
                      name: mentorData['name'] ?? '',
                      email: mentorData['email'] ?? '',
                      avatarUrl: mentorData['avatarUrl'],
                      primaryExpertise: mentorData['primaryExpertise'] ?? '',
                      expertiseTags: List<String>.from(mentorData['expertiseTags'] ?? []),
                      yearsOfExperience: mentorData['yearsOfExperience'] ?? 0,
                    )).toList();
                  });
                  
                  // Debug print to verify mentors are loaded
                  print('Mentors loaded: ${_mentors.length}');
                  for (var mentor in _mentors) {
                    print('Mentor: ${mentor.name} - ${mentor.primaryExpertise}');
                  }
                }
              });
            }
            
            // Handle mentor creation success
            if (mentorState is MentorCreated) {
              // Refresh mentors list when a new mentor is created
              context.read<MentorBloc>().add(const LoadMentors());
            }
          },
        ),
        BlocListener<CourseBloc, CourseState>(
          listener: (context, courseState) {
            if (courseState is CourseCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course "${courseState.course['title']}" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else if (courseState is CourseUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course "${courseState.course['title']}" updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else if (courseState is CourseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error ${isEditMode ? 'updating' : 'creating'} course: ${courseState.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, courseState) {
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(
                    screenTitle,
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(context),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(context),
                _buildStep2(context),
                _buildStep3(context),
                _buildStep4(context),
              ],
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(context),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigate back to main screen with the selected tab
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen(initialIndex: index)),
          );
        },
      ),
    ),
    
    // Loading overlay
    if (courseState.isLoading)
      Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: HackethosLoadingComponent(
            message: isEditMode ? 'Updating course...' : 'Creating course...',
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

  Widget _buildProgressIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact step indicator
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    Container(
                      width: isSmallScreen ? 24 : 28,
                      height: isSmallScreen ? 24 : 28,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryLight,
                                  AppTheme.primaryLight.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: !isActive
                            ? (isDark ? AppTheme.inputBorderDark : Colors.grey[300])
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryLight.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 11 : 13,
                                ),
                              ),
                      ),
                    ),
                    // Connector line
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryLight,
                                      AppTheme.primaryLight.withOpacity(0.6),
                                    ],
                                  )
                                : null,
                            color: !isCompleted
                                ? (isDark ? AppTheme.inputBorderDark : Colors.grey[300])
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          // Step title
          Text(
            _getStepTitle(),
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 13 : 15,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: isSmallScreen ? 22 : 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Essential course details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Thumbnail Upload Card
          Text(
            'Course Thumbnail *',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildThumbnailUpload(context),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Course Name
          CustomTextField(
            label: 'Course Name *',
            hint: 'e.g., Complete Web Development Bootcamp',
            controller: _courseNameController,
            prefixIcon: const Icon(Icons.title_rounded, size: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          CustomTextField(
            label: 'Course Description *',
            hint: 'Describe what students will learn...',
            controller: _descriptionController,
            isTextArea: true,
            maxLines: isSmallScreen ? 4 : 5,
            prefixIcon: const Icon(Icons.description_rounded, size: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course description';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: isSmallScreen ? 22 : 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Configuration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Settings & requirements',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Mentor Assignment
          MentorDropdown(
            selectedMentorId: _selectedMentorId,
            onMentorSelected: (mentorId) {
              setState(() {
                _selectedMentorId = mentorId;
              });
            },
            mentors: _mentors,
            isLoading: false,
            hintText: 'Select a mentor (optional)',
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Enable/Disable Course Toggle
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
              ),
            ),
            child: Row(
              children: [
                Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                  activeColor: AppTheme.primaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable this course for users',
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnabled
                            ? 'Course is visible to users'
                            : 'Course is hidden from users',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Category Selection
          Text(
            'Course Category',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildCategorySelector(context),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Price Configuration
          _buildPriceConfiguration(context),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Predefined categories
            ..._predefinedCategories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                    if (selected) {
                      _customCategoryController.clear();
                    }
                  });
                },
                selectedColor: AppTheme.primaryLight.withOpacity(0.3),
                checkmarkColor: AppTheme.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryLight
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryLight
                      : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
                ),
              );
            }).toList(),
            // Custom category option
            FilterChip(
              label: const Text('Custom'),
              selected: _selectedCategory == 'Custom',
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? 'Custom' : null;
                });
              },
              selectedColor: AppTheme.primaryLight.withOpacity(0.3),
              checkmarkColor: AppTheme.primaryLight,
              labelStyle: TextStyle(
                color: _selectedCategory == 'Custom'
                    ? AppTheme.primaryLight
                    : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                fontWeight: _selectedCategory == 'Custom' ? FontWeight.w600 : FontWeight.normal,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              side: BorderSide(
                color: _selectedCategory == 'Custom'
                    ? AppTheme.primaryLight
                    : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
              ),
            ),
          ],
        ),
        // Custom category text field (show if Custom is selected)
        if (_selectedCategory == 'Custom') ...[
          const SizedBox(height: 12),
          CustomTextField(
            controller: _customCategoryController,
            label: 'Custom Category Name',
            hint: 'e.g., Machine Learning, Web Development',
            prefixIcon: const Icon(Icons.category, size: 20),
            validator: (value) {
              if (_selectedCategory == 'Custom' && (value == null || value.isEmpty)) {
                return 'Please enter a custom category name';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPriceConfiguration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Pricing',
          style: TextStyle(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontSize: isSmallScreen ? 16 : 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Price Strike Toggle
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            ),
          ),
          child: Row(
            children: [
              Switch(
                value: _isPriceStrikeEnabled,
                onChanged: (value) {
                  setState(() {
                    _isPriceStrikeEnabled = value;
                    if (!value) {
                      // Clear strike price when disabled
                      _strikePriceController.clear();
                    }
                  });
                },
                activeColor: AppTheme.primaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enable price strike (show original price with discount)',
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Subscription Period Field
        CustomTextField(
          controller: _subscriptionPeriodController,
          label: 'Subscription Period (Days)',
          hint: 'Enter number of days (0 for lifetime access)',
          prefixIcon: const Icon(Icons.schedule),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter subscription period (0 for lifetime)';
            }
            final days = int.tryParse(value);
            if (days == null || days < 0) {
              return 'Please enter a valid number of days (0 or more)';
            }
            return null;
          },
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.green[600],
                size: isSmallScreen ? 14 : 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter 0 for lifetime access, or specify number of days for limited access',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Price Field
        CustomTextField(
          controller: _priceController,
          label: _isPriceStrikeEnabled ? 'Current Price' : 'Course Price',
          hint: 'Enter course price',
          prefixIcon: const Icon(Icons.currency_rupee),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a course price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid price';
            }
            return null;
          },
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Strike Price Field (only show if price strike is enabled)
        if (_isPriceStrikeEnabled) ...[
          CustomTextField(
            controller: _strikePriceController,
            label: 'Original Price (Strike Price)',
            hint: 'Enter original price to show with strikethrough',
            prefixIcon: const Icon(Icons.currency_rupee),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isPriceStrikeEnabled) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the original price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid original price';
                }
                // Validate that strike price is higher than current price
                final currentPrice = double.tryParse(_priceController.text);
                final strikePrice = double.tryParse(value);
                if (currentPrice != null && strikePrice != null && strikePrice <= currentPrice) {
                  return 'Original price must be higher than current price';
                }
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: isSmallScreen ? 14 : 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original price will be shown with strikethrough to indicate discount',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: isSmallScreen ? 22 : 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificate Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure course certificates',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Certificate Course Toggle
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
              ),
            ),
            child: Row(
              children: [
                Switch(
                  value: _isCertificateCourse,
                  onChanged: (value) {
                    setState(() {
                      _isCertificateCourse = value;
                    });
                  },
                  activeColor: AppTheme.primaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a certificate course',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Certificate settings (show only if certificate course is enabled)
          if (_isCertificateCourse) ...[
            // Completion Percentage
            Text(
              'Minimum Completion for Certificate: ${_completionPercentage.toInt()}%',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w700,
                fontSize: isSmallScreen ? 14 : 15,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _completionPercentage,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppTheme.primaryLight,
              onChanged: (value) {
                setState(() {
                  _completionPercentage = value;
                });
              },
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Certificate Template Upload
            Text(
              'Certificate Template',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildCertificateUpload(context),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Certificate Starting Number
            CustomTextField(
              controller: _certificateStartingNumberController,
              label: 'Certificate Starting Number',
              hint: 'e.g., 1000 (will auto-increment)',
              prefixIcon: const Icon(Icons.numbers, size: 20),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a starting certificate number';
                }
                final number = int.tryParse(value);
                if (number == null || number < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Certificate Field Positions
            Text(
              'Certificate Field Positions',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: isSmallScreen ? 14 : 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload certificate template first, then click "Set Position" to place each field on the certificate',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Name Position
            _buildPositionField(
              context,
              'Name Position',
              _namePositionX,
              _namePositionY,
              (x, y) {
                setState(() {
                  _namePositionX = x;
                  _namePositionY = y;
                });
              },
            ),
            const SizedBox(height: 12),

            // Issue Date Position
            _buildPositionField(
              context,
              'Issue Date Position',
              _issueDatePositionX,
              _issueDatePositionY,
              (x, y) {
                setState(() {
                  _issueDatePositionX = x;
                  _issueDatePositionY = y;
                });
              },
            ),
            const SizedBox(height: 12),

            // Certificate Number Position
            _buildPositionField(
              context,
              'Certificate Number Position',
              _certificateNumberPositionX,
              _certificateNumberPositionY,
              (x, y) {
                setState(() {
                  _certificateNumberPositionX = x;
                  _certificateNumberPositionY = y;
                });
              },
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Certificate Availability
            Text(
              'Certificate Availability',
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildCertificateAvailability(context),
          ],

          // Info message when certificate is not enabled
          if (!_isCertificateCourse) ...[
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: isSmallScreen ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable "This is a certificate course" to configure certificate settings for this course.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStep4(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: isSmallScreen ? 22 : 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Curriculum',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),

                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Editor/Preview Toggle
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Mode',
                  onPressed: _isPreviewMode ? () => setState(() => _isPreviewMode = false) : null,
                  isOutlined: !_isPreviewMode,
                  backgroundColor: _isPreviewMode ? null : AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Preview Mode',
                  onPressed: !_isPreviewMode ? () => setState(() => _isPreviewMode = true) : null,
                  isOutlined: _isPreviewMode,
                  backgroundColor: _isPreviewMode ? AppTheme.primaryLight : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rich Text Editor
          if (!_isPreviewMode) ...[
            _buildRichTextEditor(context),
          ] else ...[
            _buildPreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnailUpload(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final uploadHeight = isSmallScreen ? 160.0 : 200.0;

    return GestureDetector(
      onTap: _pickThumbnail,
      child: Container(
        width: double.infinity,
        height: uploadHeight,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedThumbnailFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedThumbnailFile!,
                  fit: BoxFit.cover,
                ),
              )
            : _thumbnailPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(_thumbnailPath!),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload thumbnail',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  Widget _buildCertificateUpload(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final uploadHeight = isSmallScreen ? 120.0 : 150.0;

    return GestureDetector(
      onTap: _pickCertificateImage,
      child: Container(
        width: double.infinity,
        height: uploadHeight,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedCertificateFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedCertificateFile!,
                  fit: BoxFit.cover,
                ),
              )
            : _certificateImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(_certificateImagePath!),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 32,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload certificate template',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCertificateAvailability(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('After admin review'),
          value: 'after_review',
          groupValue: _certificateAvailability,
          activeColor: AppTheme.primaryLight,
          onChanged: (value) {
            setState(() {
              _certificateAvailability = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Immediately after completion'),
          value: 'immediate',
          groupValue: _certificateAvailability,
          activeColor: AppTheme.primaryLight,
          onChanged: (value) {
            setState(() {
              _certificateAvailability = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPositionField(BuildContext context, String label, double? posX, double? posY, Function(double, double) onPositionSet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final hasPosition = posX != null && posY != null;
    final hasTemplate = _selectedCertificateFile != null || _certificateImagePath != null;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPosition
              ? Colors.green.withOpacity(0.5)
              : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPosition ? Icons.check_circle : Icons.location_on_outlined,
            color: hasPosition ? Colors.green : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            size: isSmallScreen ? 20 : 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPosition) ...[
                  const SizedBox(height: 4),
                  Text(
                    'X: ${posX.toStringAsFixed(1)}, Y: ${posY.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Adjust Position button (arrow-based picker)
          ElevatedButton.icon(
            onPressed: hasTemplate ? () => _openPositionPicker(context, label, posX, posY, onPositionSet) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasTemplate ? AppTheme.primaryLight : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.tune, size: isSmallScreen ? 14 : 16),
            label: Text(
              'Adjust',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Enter Values button (direct input)
          ElevatedButton.icon(
            onPressed: hasTemplate ? () => _openDirectValueInput(context, label, posX, posY, onPositionSet) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasTemplate ? Colors.orange : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.edit, size: isSmallScreen ? 14 : 16),
            label: Text(
              'Enter',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPositionPicker(BuildContext context, String fieldLabel, double? initialX, double? initialY, Function(double, double) onPositionSet) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CertificatePositionPicker(
        certificateFile: _selectedCertificateFile,
        certificateUrl: _certificateImagePath,
        fieldLabel: fieldLabel,
        initialX: initialX,
        initialY: initialY,
        onPositionSet: onPositionSet,
      ),
    );
  }

  void _openDirectValueInput(BuildContext context, String fieldLabel, double? initialX, double? initialY, Function(double, double) onPositionSet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xController = TextEditingController(text: initialX?.toStringAsFixed(1) ?? '100.0');
    final yController = TextEditingController(text: initialY?.toStringAsFixed(1) ?? '100.0');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(
          children: [
            Icon(Icons.edit_location_alt, color: AppTheme.primaryLight),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter $fieldLabel',
                style: TextStyle(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the X and Y coordinates in pixels (based on actual image dimensions)',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            // X Coordinate
            TextField(
              controller: xController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'X Position (px)',
                prefixIcon: Icon(Icons.arrow_forward, color: AppTheme.primaryLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Y Coordinate
            TextField(
              controller: yController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Y Position (px)',
                prefixIcon: Icon(Icons.arrow_downward, color: AppTheme.primaryLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final x = double.tryParse(xController.text) ?? 100.0;
              final y = double.tryParse(yController.text) ?? 100.0;
              onPositionSet(x, y);
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Set Position'),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextEditor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final editorHeight = isSmallScreen ? 300.0 : 400.0;

    return Container(
      height: editorHeight,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
        ),
      ),
      child: Column(
        children: [
          // Formatting Toolbar
          // _buildFormattingToolbar(context),
          SizedBox(height: isSmallScreen ? 8 : 12),
          // const Divider(),
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Text Editor
          Expanded(
            child: TextField(
              controller: _curriculumController,
              maxLines: null,
              expands: true,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.textPrimaryDark 
                    : AppTheme.textPrimaryLight,
              ),
              decoration: const InputDecoration(
                hintText: 'Start writing your course curriculum...\n\nUse the toolbar above for formatting.',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        _buildToolbarButton(Icons.format_bold, () {}),
        _buildToolbarButton(Icons.format_italic, () {}),
        _buildToolbarButton(Icons.format_list_bulleted, () {}),
        _buildToolbarButton(Icons.format_list_numbered, () {}),
        _buildToolbarButton(Icons.title, () {}),
        const Spacer(),
        
        
      ],
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final previewHeight = isSmallScreen ? 300.0 : 400.0;

    return Container(
      height: previewHeight,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          _curriculumController.text.isEmpty
              ? 'No content to preview. Switch to Edit Mode to add content.'
              : _curriculumController.text,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    final buttonSpacing = isSmallScreen ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(buttonPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  onPressed: _goToPreviousStep,
                  isOutlined: true,
                ),
              ),
            if (_currentStep > 0) SizedBox(width: buttonSpacing),
            Expanded(
              child: CustomButton(
                text: _currentStep == _totalSteps - 1 ? submitButtonText : 'Next',
                onPressed: _currentStep == _totalSteps - 1 ? _submitCourse : _goToNextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Configuration';
      case 2:
        return 'Certificate Settings';
      case 3:
        return 'Curriculum';
      default:
        return '';
    }
  }

  void _goToNextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_courseNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a course name')),
          );
          return false;
        }
        if (_descriptionController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a course description')),
          );
          return false;
        }
        return true;
      case 1:
        // Validate category
        if (_selectedCategory == 'Custom' && _customCategoryController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a custom category name')),
          );
          return false;
        }

        // Validate price fields
        if (_priceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a course price')),
          );
          return false;
        }
        if (double.tryParse(_priceController.text) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid price')),
          );
          return false;
        }
        if (_isPriceStrikeEnabled && _strikePriceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the original price')),
          );
          return false;
        }
        if (_isPriceStrikeEnabled) {
          final currentPrice = double.tryParse(_priceController.text);
          final strikePrice = double.tryParse(_strikePriceController.text);
          if (currentPrice != null && strikePrice != null && strikePrice <= currentPrice) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Original price must be higher than current price')),
            );
            return false;
          }
        }

        // Validate subscription period
        final subscriptionPeriod = int.tryParse(_subscriptionPeriodController.text);
        if (subscriptionPeriod == null || subscriptionPeriod < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid subscription period (0 or more days)')),
          );
          return false;
        }

        return true;
      case 2:
        return true; // Certificate settings are optional
      case 3:
        return true; // Curriculum can be empty initially
      default:
        return true;
    }
  }

  void _submitCourse() {
    if (_validateCurrentStep()) {
      // Determine final category value
      String? finalCategory;
      if (_selectedCategory != null) {
        if (_selectedCategory == 'Custom') {
          finalCategory = _customCategoryController.text.trim();
        } else {
          finalCategory = _selectedCategory;
        }
      }

      // Prepare course data
      final courseData = {
        'title': _courseNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mentorId': _selectedMentorId,
        'completionPercentage': _completionPercentage,
        'isCertificateCourse': _isCertificateCourse,
        'certificateAvailability': _certificateAvailability,
        // Certificate field positions
        'namePositionX': _namePositionX,
        'namePositionY': _namePositionY,
        'issueDatePositionX': _issueDatePositionX,
        'issueDatePositionY': _issueDatePositionY,
        'certificateNumberPositionX': _certificateNumberPositionX,
        'certificateNumberPositionY': _certificateNumberPositionY,
        'certificateStartingNumber': int.tryParse(_certificateStartingNumberController.text) ?? 1000,
        'currentCertificateNumber': isEditMode ? (widget.courseToEdit!['currentCertificateNumber'] ?? int.tryParse(_certificateStartingNumberController.text) ?? 1000) : int.tryParse(_certificateStartingNumberController.text) ?? 1000,
        'curriculum': _curriculumController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'isPriceStrikeEnabled': _isPriceStrikeEnabled,
        'strikePrice': _isPriceStrikeEnabled ? (double.tryParse(_strikePriceController.text) ?? 0.0) : null,
        'subscriptionPeriod': int.tryParse(_subscriptionPeriodController.text) ?? 0,
        'isPublished': _isEnabled,
        'category': finalCategory,
        'status': isEditMode ? (widget.courseToEdit!['status'] ?? 'draft') : 'draft',
        'rating': isEditMode ? (widget.courseToEdit!['rating'] ?? 0.0) : 0.0,
        'studentCount': isEditMode ? (widget.courseToEdit!['studentCount'] ?? 0) : 0,
        'createdBy': isEditMode ? (widget.courseToEdit!['createdBy'] ?? 'admin_user') : 'admin_user',
      };

      if (isEditMode) {
        // Update existing course
        context.read<CourseBloc>().add(UpdateCourse(
          courseId: widget.courseToEdit!['id'],
          courseData: courseData,
          thumbnailFile: _selectedThumbnailFile?.path,
          certificateFile: _selectedCertificateFile?.path,
          existingThumbnailUrl: _thumbnailPath,
          existingCertificateUrl: _certificateImagePath,
        ));
      } else {
        // Create new course
        context.read<CourseBloc>().add(CreateCourse(
          courseData: courseData,
          thumbnailFile: _selectedThumbnailFile?.path,
          certificateFile: _selectedCertificateFile?.path,
        ));
      }
    }
  }

  void _pickThumbnail() async {
    try {
      // Show options for camera or gallery
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickThumbnailFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickThumbnailFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking thumbnail: $e')),
      );
    }
  }

  void _pickThumbnailFromCamera() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: true);
      
      if (imageFile != null) {
        setState(() {
          _selectedThumbnailFile = imageFile;
          _thumbnailPath = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail selected successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _pickThumbnailFromGallery() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: false);
      
      if (imageFile != null) {
        setState(() {
          _selectedThumbnailFile = imageFile;
          _thumbnailPath = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail selected successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _pickCertificateImage() async {
    try {
      // Show options for camera or gallery
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickCertificateFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickCertificateFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking certificate image: $e')),
      );
    }
  }

  void _pickCertificateFromCamera() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: true);
      
      if (imageFile != null) {
        setState(() {
          _selectedCertificateFile = imageFile;
          _certificateImagePath = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate template selected successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _pickCertificateFromGallery() async {
    try {
      final imageFile = await _userRepository.pickImage(fromCamera: false);
      
      if (imageFile != null) {
        setState(() {
          _selectedCertificateFile = imageFile;
          _certificateImagePath = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate template selected successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }
}

// Certificate Position Picker Dialog
class _CertificatePositionPicker extends StatefulWidget {
  final File? certificateFile;
  final String? certificateUrl;
  final String fieldLabel;
  final double? initialX;
  final double? initialY;
  final Function(double, double) onPositionSet;

  const _CertificatePositionPicker({
    required this.certificateFile,
    required this.certificateUrl,
    required this.fieldLabel,
    this.initialX,
    this.initialY,
    required this.onPositionSet,
  });

  // Get field-specific color
  Color get fieldColor {
    if (fieldLabel.contains('Name')) {
      return Colors.blue;
    } else if (fieldLabel.contains('Date')) {
      return Colors.purple;
    } else if (fieldLabel.contains('Number')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  @override
  State<_CertificatePositionPicker> createState() => _CertificatePositionPickerState();
}

class _CertificatePositionPickerState extends State<_CertificatePositionPicker> {
  late double _selectedX;
  late double _selectedY;
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey();
  bool _showGrid = true;
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  double _maxX = 1000.0; // Actual image width
  double _maxY = 1000.0; // Actual image height
  double _imageOffsetX = 0.0; // Image offset from container left
  double _imageOffsetY = 0.0; // Image offset from container top
  double _imageRenderWidth = 0.0; // Rendered image width
  double _imageRenderHeight = 0.0; // Rendered image height

  @override
  void initState() {
    super.initState();
    // Initialize with existing values if provided, otherwise use defaults
    _selectedX = widget.initialX ?? 100.0;
    _selectedY = widget.initialY ?? 100.0;
    _xController = TextEditingController(text: _selectedX.toStringAsFixed(1));
    _yController = TextEditingController(text: _selectedY.toStringAsFixed(1));

    // Update max dimensions after first frame when image is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImageBounds();
    });
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  Future<void> _updateImageBounds() async {
    final RenderBox? imageRenderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;

    if (imageRenderBox != null && containerRenderBox != null) {
      // Get actual image dimensions
      final imageWidget = _imageKey.currentWidget;
      if (imageWidget is Image) {
        final imageProvider = imageWidget.image;
        final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
        final Completer<void> completer = Completer<void>();

        late ImageStreamListener listener;
        listener = ImageStreamListener((ImageInfo info, bool _) {
          final imageWidth = info.image.width.toDouble();
          final imageHeight = info.image.height.toDouble();
          final containerWidth = containerRenderBox.size.width;
          final containerHeight = containerRenderBox.size.height;

          // Calculate scale factor for BoxFit.contain
          final scaleX = containerWidth / imageWidth;
          final scaleY = containerHeight / imageHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;

          // Calculate rendered image size
          final renderedWidth = imageWidth * scale;
          final renderedHeight = imageHeight * scale;

          // Calculate offset (image is centered)
          final offsetX = (containerWidth - renderedWidth) / 2;
          final offsetY = (containerHeight - renderedHeight) / 2;

          setState(() {
            _maxX = imageWidth; // Use actual image pixels
            _maxY = imageHeight;
            _imageOffsetX = offsetX;
            _imageOffsetY = offsetY;
            _imageRenderWidth = renderedWidth;
            _imageRenderHeight = renderedHeight;
          });

          print('Actual image: ${imageWidth}x$imageHeight, Rendered: ${renderedWidth.toStringAsFixed(1)}x${renderedHeight.toStringAsFixed(1)}, Offset: (${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');

          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        });

        stream.addListener(listener);
        await completer.future;
      }
    }
  }

  // Convert display position (in container) to image coordinates
  double _displayToImageX(double displayX) {
    if (_imageRenderWidth == 0) return displayX;
    final relativeX = (displayX - _imageOffsetX).clamp(0.0, _imageRenderWidth);
    return (relativeX / _imageRenderWidth) * _maxX;
  }

  double _displayToImageY(double displayY) {
    if (_imageRenderHeight == 0) return displayY;
    final relativeY = (displayY - _imageOffsetY).clamp(0.0, _imageRenderHeight);
    return (relativeY / _imageRenderHeight) * _maxY;
  }

  // Convert image coordinates to display position
  double _imageToDisplayX(double imageX) {
    if (_maxX == 0) return imageX;
    return _imageOffsetX + (imageX / _maxX) * _imageRenderWidth;
  }

  double _imageToDisplayY(double imageY) {
    if (_maxY == 0) return imageY;
    return _imageOffsetY + (imageY / _maxY) * _imageRenderHeight;
  }

  void _updatePosition(double x, double y, {bool updateControllers = true}) {
    setState(() {
      _selectedX = x.clamp(0.0, _maxX);
      _selectedY = y.clamp(0.0, _maxY);
      // Only update controller text if not coming from the text field itself
      if (updateControllers) {
        _xController.text = _selectedX.toStringAsFixed(1);
        _yController.text = _selectedY.toStringAsFixed(1);
      }
    });
  }

  void _movePosition(double dx, double dy) {
    _updatePosition(_selectedX + dx, _selectedY + dy, updateControllers: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set ${widget.fieldLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use arrow buttons or enter coordinates directly',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid toggle button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showGrid = !_showGrid;
                      });
                    },
                    icon: Icon(
                      _showGrid ? Icons.grid_on : Icons.grid_off,
                      color: Colors.white,
                    ),
                    tooltip: _showGrid ? 'Hide Grid' : 'Show Grid',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Certificate Image with tap detection
            SizedBox(
              height: 400, // Fixed height to avoid Expanded in ScrollView
              child: Container(
                key: _containerKey,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate display position from image coordinates
                      final displayX = _imageToDisplayX(_selectedX);
                      final displayY = _imageToDisplayY(_selectedY);

                      return Stack(
                        children: [
                          // Certificate Image (non-interactive for accurate positioning)
                          Center(
                            child: widget.certificateFile != null
                                ? Image.file(
                                    widget.certificateFile!,
                                    key: _imageKey,
                                    fit: BoxFit.contain,
                                  )
                                : widget.certificateUrl != null
                                    ? Image.network(
                                        widget.certificateUrl!,
                                        key: _imageKey,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Text('No certificate template available'),
                                      ),
                          ),

                          // Grid overlay
                          if (_showGrid)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _GridPainter(
                                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                                  ),
                                ),
                              ),
                            ),

                          // Crosshair lines (X and Y axis) - field-specific colors
                          // Vertical line (Y-axis)
                          Positioned(
                            left: displayX,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.fieldColor.withOpacity(0.0),
                                      widget.fieldColor.withOpacity(0.9),
                                      widget.fieldColor.withOpacity(0.9),
                                      widget.fieldColor.withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.fieldColor.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Horizontal line (X-axis)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: displayY,
                            child: IgnorePointer(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.fieldColor.withOpacity(0.0),
                                      widget.fieldColor.withOpacity(0.9),
                                      widget.fieldColor.withOpacity(0.9),
                                      widget.fieldColor.withOpacity(0.0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.fieldColor.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Position marker with field-specific color
                          Positioned(
                            left: displayX - 30,
                            top: displayY - 30,
                            child: IgnorePointer(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.fieldColor.withOpacity(0.15),
                                  border: Border.all(
                                    color: widget.fieldColor,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.fieldColor.withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.my_location,
                                    color: widget.fieldColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Position Info and Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.inputBorderDark : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Coordinate Input Fields
                  Row(
                    children: [
                      // X Coordinate
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_forward, size: 16, color: widget.fieldColor),
                                const SizedBox(width: 6),
                                Text(
                                  'X Position (px)',
                                  style: TextStyle(
                                    color: widget.fieldColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _xController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onChanged: (value) {
                                final x = double.tryParse(value);
                                if (x != null) {
                                  _updatePosition(x, _selectedY, updateControllers: false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Y Coordinate
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 16, color: widget.fieldColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Y Position (px)',
                                  style: TextStyle(
                                    color: widget.fieldColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _yController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.fieldColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onChanged: (value) {
                                final y = double.tryParse(value);
                                if (y != null) {
                                  _updatePosition(_selectedX, y, updateControllers: false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Arrow Controls
                  Text(
                    'Fine-tune Position',
                    style: TextStyle(
                      color: widget.fieldColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // D-Pad Style Arrow Buttons
                      Column(
                        children: [
                          // Up button
                          _buildArrowButton(
                            icon: Icons.keyboard_arrow_up,
                            onPressed: () => _movePosition(0, -1),
                            onLongPress: () => _movePosition(0, -10),
                          ),
                          Row(
                            children: [
                              // Left button
                              _buildArrowButton(
                                icon: Icons.keyboard_arrow_left,
                                onPressed: () => _movePosition(-1, 0),
                                onLongPress: () => _movePosition(-10, 0),
                              ),
                              const SizedBox(width: 8),
                              // Center info
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: widget.fieldColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: widget.fieldColor.withOpacity(0.3)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.control_camera, color: widget.fieldColor, size: 20),
                                    const SizedBox(height: 2),
                                    Text(
                                      '±1px',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: widget.fieldColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right button
                              _buildArrowButton(
                                icon: Icons.keyboard_arrow_right,
                                onPressed: () => _movePosition(1, 0),
                                onLongPress: () => _movePosition(10, 0),
                              ),
                            ],
                          ),
                          // Down button
                          _buildArrowButton(
                            icon: Icons.keyboard_arrow_down,
                            onPressed: () => _movePosition(0, 1),
                            onLongPress: () => _movePosition(0, 10),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Quick jump buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickButton('+10 X', () => _movePosition(10, 0)),
                          const SizedBox(height: 6),
                          _buildQuickButton('-10 X', () => _movePosition(-10, 0)),
                          const SizedBox(height: 6),
                          _buildQuickButton('+10 Y', () => _movePosition(0, 10)),
                          const SizedBox(height: 6),
                          _buildQuickButton('-10 Y', () => _movePosition(0, -10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap: ±1px • Hold: ±10px',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onPositionSet(_selectedX, _selectedY);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.fieldColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Confirm Position'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: widget.fieldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.fieldColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: widget.fieldColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.fieldColor.withOpacity(0.2),
        foregroundColor: widget.fieldColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(70, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Custom Grid Painter for certificate position picker
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSpacing = 50.0; // Grid spacing in pixels

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
