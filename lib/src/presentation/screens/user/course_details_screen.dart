import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../../core/bloc/quiz/quiz_bloc.dart';
import '../../../core/bloc/quiz/quiz_event.dart';
import '../../../core/bloc/quiz/quiz_state.dart';
import '../../../data/models/quiz_model.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/bloc/cart/cart_state.dart';
import '../../../core/bloc/course_access/course_access_bloc.dart';
import '../../../core/bloc/course_access/course_access_event.dart';
import '../../../core/bloc/course_access/course_access_state.dart';
import '../../widgets/course/course_video_header.dart';
import '../../widgets/course/course_info_section.dart';
import '../../widgets/course/course_modules_section.dart';
import '../../widgets/course/course_quizzes_section.dart';
import '../../widgets/course/course_pricing_section.dart';
import '../../widgets/course/course_overview_tab.dart';
import '../../widgets/course/course_reviews_tab.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/cart/add_to_cart_button.dart';
import 'cart_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _modules = [];
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedVideo;
  late TabController _tabController;
  bool _hasCourseAccess = false;
  bool _isCheckingAccess = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCourseContent();
    _checkCourseAccess();
    // Load full cart to get complete cart status
    context.read<CartBloc>().add(const LoadCartWithCourseData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCourseContent() {
    // Load modules
    context.read<CourseBloc>().add(LoadCourseModules(widget.course['id']));
    // Load quizzes
    context.read<QuizBloc>().add(LoadCourseQuizzes(courseId: widget.course['id']));
  }

  void _checkCourseAccess() {
    context.read<CourseAccessBloc>().add(
      CheckCourseAccess(courseId: widget.course['id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is ModulesLoaded) {
              setState(() {
                _modules = state.modules;
                _isLoading = false;
              });
            } else if (state is VideosLoaded) {
              // Handle video loading for modules
              setState(() {
                // Videos are handled by CourseModulesSection
              });
            }
          },
        ),
        BlocListener<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizzesLoaded) {
              setState(() {
                _quizzes = state.quizzes;
              });
            }
          },
        ),
        BlocListener<CourseAccessBloc, CourseAccessState>(
          listener: (context, state) {
            if (state is CourseAccessChecked) {
              setState(() {
                _hasCourseAccess = state.hasAccess;
                _isCheckingAccess = false;
              });
              print('Course access checked in details: ${state.hasAccess}');
            } else if (state is CourseAccessError) {
              setState(() {
                _isCheckingAccess = false;
              });
              print('Course access error in details: ${state.error}');
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.course['title'] ?? 'Course Details',
            style: const TextStyle(
              fontFamily: 'InstrumentSerif',
              fontStyle: FontStyle.italic,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Course Header with Video Player
              CourseVideoHeader(
                course: widget.course,
                isDark: isDark,
                selectedVideo: _selectedVideo,
                onVideoTap: _onVideoHeaderTap,
                hasCourseAccess: _hasCourseAccess,
                modules: _modules,
                onNextVideo: _onVideoTap,
                onPreviousVideo: _onVideoTap,
              ),
              // Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    indicatorColor: AppTheme.primaryLight,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                    labelColor: AppTheme.primaryLight,
                    unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return AppTheme.primaryLight.withOpacity(0.1);
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return AppTheme.primaryLight.withOpacity(0.05);
                        }
                        return null;
                      },
                    ),
                    splashFactory: InkRipple.splashFactory,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Overview'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Modules'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Quizzes'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Reviews'),
                        ),
                      ),
                    ],
                  ),
                  isDark: isDark,
                ),
              ),
            ];
          },
          body: Column(
            children: [
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Overview Tab
                    SingleChildScrollView(
                      child: CourseOverviewTab(
                        course: widget.course,
                        isDark: isDark,
                        quizzes: _quizzes,
                      ),
                    ),
                    
                    // Modules Tab
                    SingleChildScrollView(
                      child: CourseModulesSection(
                        course: widget.course,
                        modules: _modules,
                        isLoading: _isLoading,
                        isDark: isDark,
                        onModuleTap: _onModuleTap,
                        onPremiumTap: _showPremiumLockDialog,
                        onVideoTap: _onVideoTap,
                        selectedVideoId: _selectedVideo?['id'],
                      ),
                    ),
                    
                    // Quizzes Tab
                    SingleChildScrollView(
                      child: CourseQuizzesSection(
                        course: widget.course,
                        quizzes: _quizzes,
                        isLoading: _isLoading,
                        isDark: isDark,
                        hasCourseAccess: _hasCourseAccess,
                      ),
                    ),
                    
                    // Reviews Tab
                    CourseReviewsTab(
                      course: widget.course,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              // Show pricing bar only if course is not purchased
              if (!_hasCourseAccess)
                _buildFloatingPricingBar(isDark)
              else
                _buildPurchasedCourseIndicator(isDark),
            ],
          ),
        ),
      ),
    );
  }

  void _onVideoHeaderTap() {
    print('Play button tapped - modules count: ${_modules.length}');
    
    // Find the first accessible video to play in header
    for (final module in _modules) {
      final videos = module['videos'] as List<dynamic>? ?? [];
      print('Module ${module['title']} has ${videos.length} videos');
      
      for (final video in videos) {
        final videoMap = Map<String, dynamic>.from(video as Map);
        final isPremium = videoMap['isPremium'] ?? false;
        final hasAccess = !isPremium || _hasCourseAccess;
        print('Video ${videoMap['title']} is premium: $isPremium, has access: $hasAccess');
        
        if (hasAccess) {
          print('Selecting video: ${videoMap['title']}');
          setState(() {
            _selectedVideo = videoMap;
          });
          return;
        }
      }
    }
    
    print('No accessible videos found');
    // Show a message if no accessible videos are available
    if (!_hasCourseAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase the course to access premium content'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No videos available in this course'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onVideoTap(Map<String, dynamic> video) {
    // Videos inherit premium status from their parent module
    // We need to find which module this video belongs to
    final moduleId = video['moduleId'];
    final module = _modules.firstWhere(
      (m) => m['id'] == moduleId,
      orElse: () => <String, dynamic>{},
    );
    final isPremium = module['isPremium'] ?? (module['type'] == 'premium');
    final hasAccess = !isPremium || _hasCourseAccess;
    
    if (hasAccess) {
      setState(() {
        _selectedVideo = video;
      });
    }
    // Premium videos without access are handled by VideoListWidget's onPremiumTap
  }

  void _onModuleTap(Map<String, dynamic> module) {
    final isPremium = module['isPremium'] ?? (module['type'] == 'premium');
    final hasAccess = !isPremium || _hasCourseAccess;
    
    // Only handle accessible modules
    if (hasAccess) {
      // Find first accessible video in this module and auto-play it
      final videos = module['videos'] as List<dynamic>? ?? [];
      for (final video in videos) {
        final videoMap = Map<String, dynamic>.from(video as Map);
        final videoIsPremium = videoMap['isPremium'] ?? false;
        final videoHasAccess = !videoIsPremium || _hasCourseAccess;
        if (videoHasAccess) {
          setState(() {
            _selectedVideo = videoMap;
          });
          return;
        }
      }
    }
    // Premium modules without access are handled by CourseModulesSection with snackbar
  }


  void _showVideoPlayer(Map<String, dynamic> module) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          width: double.infinity,
          height: 300,
          child: Column(
            children: [
              // Video Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        module['title'] ?? 'Video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Video Placeholder
              Expanded(
                child: Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Video Player',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Video will play here',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizDialog(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quiz['title'] ?? 'Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${quiz['description'] ?? 'No description'}'),
            const SizedBox(height: 16),
            Text('Total Marks: ${quiz['totalMarks'] ?? 0}'),
            Text('Questions: ${(quiz['questions'] as List?)?.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          CustomButton(
            text: 'Start Quiz',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quiz functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPremiumLockDialog(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Content'),
          ],
        ),
        content: Text(
          _hasCourseAccess 
              ? 'You have access to this course, but this specific content is still locked.'
              : 'This ${content['title'] ?? 'content'} is part of our premium course. '
                'Purchase the course to access all premium content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (!_hasCourseAccess)
            CustomButton(
              text: 'Add to Cart',
              onPressed: () {
                Navigator.pop(context);
                // Add the course to cart
                context.read<CartBloc>().add(AddToCart(course: widget.course));
              },
            ),
        ],
      ),
    );
  }

Widget _buildFloatingPricingBar(bool isDark) {
  final strikePrice = widget.course['strikePrice']?.toDouble() ?? 0.0;
  final currentPrice = widget.course['price']?.toDouble() ?? 0.0;
  final isPriceStrikeEnabled = widget.course['isPriceStrikeEnabled'] ?? false;
  final hasDiscount = isPriceStrikeEnabled && strikePrice > currentPrice && strikePrice > 0;
  final discountPercentage = hasDiscount 
      ? ((strikePrice - currentPrice) / strikePrice * 100).round()
      : 0;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      border: Border(
        top: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Price Section (only show if user doesn't have course access)
          if (!_hasCourseAccess)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDiscount)
                  Text(
                    '₹${strikePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                      fontSize: 14,
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      '₹${currentPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discountPercentage% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          
          // Course Access Status or Add to Cart Button
          _buildCourseAccessButton(isDark),
        ],
      ),
    ),
  );
}

Widget _buildCourseAccessButton(bool isDark) {
  // If user has course access, show access status instead of cart button
  if (_hasCourseAccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Course Purchased',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // If user doesn't have access, show cart functionality
  return BlocConsumer<CartBloc, CartState>(
    listener: (context, state) {
      if (state is CartSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
            ),
          ),
        );
      } else if (state is CartError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    builder: (context, state) {
      final isLoading = state is CartLoading;
      bool isInCart = false;
      
      if (state is CartLoaded) {
        isInCart = state.cartStatus[widget.course['id']] ?? false;
        print('Course Details - Cart status for course ${widget.course['id']}: $isInCart');
        print('Course Details - Cart status map: ${state.cartStatus}');
        print('Course Details - Total cart items: ${state.cartItems.length}');
      }
      
      if (isInCart) {
        return ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'View in Cart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      
      return ElevatedButton(
        onPressed: isLoading ? null : () {
          context.read<CartBloc>().add(AddToCart(course: widget.course));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    },
  );
}

  void _onAddToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.course['title']}" to cart'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildPurchasedCourseIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated checkmark icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Success text
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Purchased',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'You have full access to all content',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Sparkle icon for extra appeal
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}
