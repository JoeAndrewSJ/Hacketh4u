import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../../core/bloc/banner/banner_bloc.dart';
import '../../../core/bloc/banner/banner_event.dart';
import '../../../core/bloc/banner/banner_state.dart';
import '../../../data/models/banner_model.dart';
import '../../widgets/course/course_card.dart';
import '../../widgets/common/widgets.dart';
import 'course_details_screen.dart';
import 'all_courses_screen.dart';
import 'cart_screen.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/bloc/cart/cart_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import 'dart:async';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  List<BannerModel> _banners = [];
  List<Map<String, dynamic>> _purchasedCourses = [];
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentBannerIndex = 0;
  bool _hasShownCourseSnackbar = false;
  Timer? _snackbarTimer;
  String? _selectedCategoryFilter;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadBanners();
    _loadCart();
    _loadPurchasedCourses();
    _searchController.addListener(_onSearchChanged);
    
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Start auto-play animation
    _startAutoPlay();
    
    // Show welcome popup only on first login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomePopup();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    _snackbarTimer?.cancel();
    super.dispose();
  }

  void _loadCourses() {
    context.read<CourseBloc>().add(const LoadCourses());
  }

  void _loadBanners() {
    context.read<BannerBloc>().add(LoadBanners());
  }

  void _loadCart() {
    context.read<CartBloc>().add(LoadCart());
  }

  void _loadPurchasedCourses() {
    context.read<CourseAccessBloc>().add(const LoadPurchasedCoursesWithDetails());
  }

  void _startAutoPlay() {
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextBanner();
      }
    });
    _animationController.forward();
  }

  void _nextBanner() {
    if (_banners.isNotEmpty) {
      setState(() {
        _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
      });
      _pageController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        // Search filter
        final title = course['title']?.toString().toLowerCase() ?? '';
        final description = course['description']?.toString().toLowerCase() ?? '';
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            title.contains(searchQuery) ||
            description.contains(searchQuery);

        // Category filter
        final courseCategory = course['category']?.toString() ?? '';
        final matchesCategory = _selectedCategoryFilter == null ||
            _selectedCategoryFilter == 'All' ||
            courseCategory == _selectedCategoryFilter;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is CourseLoaded) {
              setState(() {
                // Filter to show only published courses (isPublished = true)
                _courses = state.courses.where((course) {
                  return course['isPublished'] == true;
                }).toList();

                // Extract unique categories
                final categories = <String>{};
                for (var course in _courses) {
                  final category = course['category'];
                  if (category != null && category.toString().isNotEmpty) {
                    categories.add(category.toString());
                  }
                }
                _availableCategories = categories.toList()..sort();

                _applyFilters();
              });
            } else if (state is CourseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<BannerBloc, BannerState>(
          listener: (context, state) {
            if (state is BannersLoaded) {
              setState(() {
                _banners = state.banners.where((banner) => banner.isActive).toList();
              });
            }
          },
        ),
        BlocListener<CourseAccessBloc, CourseAccessState>(
          listener: (context, state) {
            if (state is PurchasedCoursesWithDetailsLoaded) {
              setState(() {
                // Filter to show only incomplete courses (progress < 100%)
                _purchasedCourses = state.purchasedCourses.where((course) {
                  final progressData = course['progress'] as Map<String, dynamic>?;
                  final progressPercentage = progressData?['overallCompletionPercentage'] as double? ?? 0.0;
                  return progressPercentage < 100.0;
                }).toList();

                // Shuffle to show different courses each time
                if (_purchasedCourses.isNotEmpty) {
                  _purchasedCourses.shuffle();
                }
              });

              // Show floating snackbar after data is loaded
              if (!_hasShownCourseSnackbar) {
                _hasShownCourseSnackbar = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _showCourseSnackbar();
                  }
                });
              }
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Hackethos4U',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                int itemCount = 0;
                if (state is CartLoaded) {
                  itemCount = state.cartItems.length;
                }
                
                return _buildCartIconWithBadge(itemCount);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top Clipped Section with Search Bar and Profile Info
              _buildTopClippedSection(isDark),

              // Banner Carousel
              if (_banners.isNotEmpty) _buildBannerCarousel(isDark),

              // Courses Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Courses Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Courses',
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToAllCourses(context),
                          child: Text(
                            'See All',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category Filter Chips
                  if (_availableCategories.isNotEmpty)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // "All" chip
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategoryFilter == null || _selectedCategoryFilter == 'All',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryFilter = selected ? 'All' : null;
                                  _applyFilters();
                                });
                              },
                              selectedColor: AppTheme.primaryLight.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryLight,
                              labelStyle: TextStyle(
                                color: (_selectedCategoryFilter == null || _selectedCategoryFilter == 'All')
                                    ? AppTheme.primaryLight
                                    : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                                fontWeight: (_selectedCategoryFilter == null || _selectedCategoryFilter == 'All')
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: (_selectedCategoryFilter == null || _selectedCategoryFilter == 'All')
                                    ? AppTheme.primaryLight
                                    : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
                              ),
                            ),
                          ),
                          // Category chips
                          ..._availableCategories.map((category) {
                            final isSelected = _selectedCategoryFilter == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryFilter = selected ? category : 'All';
                                    _applyFilters();
                                  });
                                },
                                selectedColor: AppTheme.primaryLight.withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryLight,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primaryLight
                                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryLight
                                      : (isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  // Horizontal Courses List
                  SizedBox(
                    height: 240,
                    child: BlocBuilder<CourseBloc, CourseState>(
                      builder: (context, state) {
                        if (state.isLoading && _courses.isEmpty) {
                          return const SizedBox(
                            height: 240,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (_filteredCourses.isEmpty) {
                          return SizedBox(
                            height: 240,
                            child: _buildEmptyState(context, isDark),
                          );
                        }

                        return SizedBox(
                          height: 240,
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _loadCourses();
                            },
                            child: _buildHorizontalCoursesList(isDark),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseSnackbar() {
    // Cancel any existing timer
    _snackbarTimer?.cancel();

    // Determine message and navigation based on purchased courses
    final hasIncompleteCourses = _purchasedCourses.isNotEmpty;
    final message = hasIncompleteCourses
        ? 'Continue your learning'
        : 'Start your journey, browse courses';

    final subtitle = hasIncompleteCourses && _purchasedCourses.isNotEmpty
        ? _purchasedCourses[0]['title'] as String? ?? ''
        : '';

    final snackBar = SnackBar(
      content: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (hasIncompleteCourses && _purchasedCourses.isNotEmpty) {
              // Navigate to the incomplete course
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailsScreen(course: _purchasedCourses[0]),
                ),
              );
            } else {
              // Navigate to all courses screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllCoursesScreen(),
                ),
              );
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasIncompleteCourses ? Icons.play_circle_outline : Icons.explore,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppTheme.primaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: const Duration(seconds: 5),
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Auto-hide after 5 seconds
    _snackbarTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  Widget _buildBannerCarousel(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Banner Images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
              _animationController.reset();
              _animationController.forward();
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () => _handleBannerTap(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark ? AppTheme.surfaceDark : Colors.grey[200],
                              child: Icon(
                                Icons.campaign,
                                size: 48,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDark ? AppTheme.surfaceDark : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                        
                        // YouTube indicator overlay
                        if (banner.youtubeUrl != null && banner.youtubeUrl!.isNotEmpty)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        
                        // Clickable indicator overlay
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                ),
              );
            },
          ),
          
          // Page Indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentBannerIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCoursesList(bool isDark) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _filteredCourses.length + 1, // +1 for "See All" card
      itemBuilder: (context, index) {
        if (index == _filteredCourses.length) {
          // "See All" card
          return _buildSeeAllCard(context, isDark);
        }
        
        final course = _filteredCourses[index];
        return _buildHorizontalCourseCard(context, course, isDark);
      },
    );
  }

  Widget _buildSeeAllCard(BuildContext context, bool isDark) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToAllCourses(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'See All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${_courses.length} courses',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCourseCard(BuildContext context, Map<String, dynamic> course, bool isDark) {
    return SizedBox(
      width: 240, // Made even wider from 200 to 240

      child: CourseCard(
        id: course['id'] ?? '',
        title: course['title'] ?? 'Untitled Course',
        description: course['description'] ?? 'No description available',
        thumbnailUrl: course['thumbnailUrl'] ?? '',
        rating: (course['rating'] ?? 0.0).toDouble(),
        studentCount: course['studentCount'] ?? 0,
        duration: _formatDuration(course['totalDuration'] ?? 0),
        isAdmin: false,
        onTap: () => _navigateToCourseDetails(context, course),
      ),
    );
  }
  

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? 'No Courses Found' : 'No Courses Available',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try adjusting your search terms'
                : 'Check back later for new courses',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isNotEmpty)
            CustomButton(
              text: 'Clear Search',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
              isOutlined: true,
            ),
        ],
      ),
    );
  }

  void _navigateToCourseDetails(BuildContext context, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }

  void _navigateToAllCourses(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCoursesScreen(),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Widget _buildSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToAllCourses(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: AppTheme.primaryLight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search by title or description...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopClippedSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(isDark),
              const SizedBox(height: 20),
              
              // Search Bar
              _buildSearchBar(isDark),
              
              const SizedBox(height: 15),
              
              // Quick Stats
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        // Profile Avatar
        // Container(
        //   width: 50,
        //   height: 50,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: Colors.white,
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.1),
        //         blurRadius: 8,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: ClipOval(
        //     child: Image.asset(
        //       'assets/profileicon.png',
        //       width: 50,
        //       height: 50,
        //       fit: BoxFit.cover,
        //       errorBuilder: (context, error, stackTrace) {
        //         return Icon(
        //           Icons.person,
        //           size: 30,
        //           color: AppTheme.primaryLight,
        //         );
        //       },
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 15),
        //
        // // Welcome Text
        // Expanded(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'Welcome !',
        //         style: AppTextStyles.bodySmall.copyWith(
        //           color: Colors.white.withOpacity(0.9),
        //           fontSize: 14,
        //         ),
        //       ),
        //       Text(
        //         'Ready to learn?',
        //         style: AppTextStyles.h3.copyWith(
        //           color: Colors.white,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        //
        
      ],
    );
  }

  Future<void> _checkAndShowWelcomePopup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome_popup') ?? false;
    
    if (!hasSeenWelcome) {
      _showWelcomePopup();
    }
  }

  // Method to reset welcome popup (useful for testing)
  static Future<void> resetWelcomePopup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_seen_welcome_popup');
  }

  void _showWelcomePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomePopup(
        onClose: () async {
          // Mark welcome popup as seen
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_welcome_popup', true);
        },
      ),
    );
  }

  Widget _buildCartIconWithBadge(int itemCount) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            );
          },
        ),
        if (itemCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleBannerTap(BannerModel banner) async {
    if (banner.youtubeUrl != null && banner.youtubeUrl!.isNotEmpty) {
      // Open YouTube URL
      final Uri url = Uri.parse(banner.youtubeUrl!);
      
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // Opens in YouTube app or browser
          );
        } else {
          // Show error message if URL can't be launched
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to open YouTube video'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      } catch (e) {
        // Show error message if there's an exception
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening video: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } else {
      // Show message for banners without YouTube URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This banner is not linked to any video'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
