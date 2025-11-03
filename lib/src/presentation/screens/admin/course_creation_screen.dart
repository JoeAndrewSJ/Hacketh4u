import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final int _totalSteps = 3;
  
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
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Certificate Image Upload (if certificate course is enabled)
          if (_isCertificateCourse) ...[
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
          prefixIcon: const Icon(Icons.attach_money),
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
            prefixIcon: const Icon(Icons.attach_money),
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
