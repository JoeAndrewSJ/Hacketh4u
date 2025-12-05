import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import 'course_details_screen.dart';
import 'my_purchases_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String? transactionId;
  final double? amount;
  final String? errorMessage;
  final List<dynamic>? purchasedCourses;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    this.transactionId,
    this.amount,
    this.errorMessage,
    this.purchasedCourses,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
      _fadeController.forward();
      if (widget.isSuccess) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;
    final isTinyScreen = screenHeight < 600 || screenWidth < 320;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: Stack(
          children: [
            // Confetti for success
            if (widget.isSuccess)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                  numberOfParticles: 30,
                  gravity: 0.3,
                ),
              ),

            // Main Content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section with icon and title
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isTinyScreen ? 10 : (isSmallScreen ? 15 : 20)),

                          // Animated Icon/Lottie
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildAnimatedIcon(isDark, isSmallScreen, isTinyScreen),
                          ),

                          SizedBox(height: isTinyScreen ? 12 : (isSmallScreen ? 16 : 20)),

                          // Title
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              widget.isSuccess ? 'Payment Successful!' : 'Payment Failed',
                              style: TextStyle(
                                fontSize: isTinyScreen ? 20 : (isSmallScreen ? 22 : 26),
                                fontWeight: FontWeight.bold,
                                color: widget.isSuccess
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: isTinyScreen ? 6 : (isSmallScreen ? 8 : 10)),

                          // Subtitle
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              widget.isSuccess
                                  ? 'Your courses are ready to access!'
                                  : 'Something went wrong with your payment',
                              style: TextStyle(
                                fontSize: isTinyScreen ? 12 : (isSmallScreen ? 13 : 14),
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle section with details
                    Flexible(
                      flex: widget.isSuccess && widget.purchasedCourses != null ? 2 : 1,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: isTinyScreen ? 12 : (isSmallScreen ? 16 : 20)),

                            // Details Card
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildDetailsCard(isDark, isSmallScreen, isTinyScreen),
                            ),

                            // Purchased Courses (if success)
                            if (widget.isSuccess && widget.purchasedCourses != null) ...[
                              SizedBox(height: isTinyScreen ? 12 : (isSmallScreen ? 16 : 20)),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildPurchasedCourses(isDark, isSmallScreen, isTinyScreen),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bottom section with buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildActionButtons(isDark, isSmallScreen, isTinyScreen),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark, bool isSmallScreen, bool isTinyScreen) {
    final iconSize = isTinyScreen ? 80.0 : (isSmallScreen ? 100.0 : 120.0);
    final innerIconSize = isTinyScreen ? 40.0 : (isSmallScreen ? 50.0 : 60.0);

    if (widget.isSuccess) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: isSmallScreen ? 15 : 25,
              offset: Offset(0, isSmallScreen ? 8 : 12),
            ),
          ],
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: innerIconSize,
        ),
      );
    } else {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.red[400]!, Colors.red[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: isSmallScreen ? 15 : 25,
              offset: Offset(0, isSmallScreen ? 8 : 12),
            ),
          ],
        ),
        child: Icon(
          Icons.error_rounded,
          color: Colors.white,
          size: innerIconSize,
        ),
      );
    }
  }

  Widget _buildDetailsCard(bool isDark, bool isSmallScreen, bool isTinyScreen) {
    return Container(
      padding: EdgeInsets.all(isTinyScreen ? 12 : (isSmallScreen ? 16 : 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.surfaceDark, AppTheme.surfaceDark]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: Offset(0, isSmallScreen ? 4 : 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.isSuccess) ...[
            _buildDetailRow(
              icon: Icons.payment_rounded,
              label: 'Transaction ID',
              value: widget.transactionId ?? 'N/A',
              isDark: isDark,
              isSmallScreen: isSmallScreen,
              isTinyScreen: isTinyScreen,
            ),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            _buildDetailRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Amount Paid',
              value: '₹${widget.amount?.toStringAsFixed(0) ?? '0'}',
              isDark: isDark,
              valueColor: Colors.green[600],
              isHighlight: true,
              isSmallScreen: isSmallScreen,
              isTinyScreen: isTinyScreen,
            ),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Date & Time',
              value: _formatDateTime(DateTime.now()),
              isDark: isDark,
              isSmallScreen: isSmallScreen,
              isTinyScreen: isTinyScreen,
            ),
          ] else ...[
            _buildDetailRow(
              icon: Icons.error_outline_rounded,
              label: 'Error',
              value: widget.errorMessage ?? 'Payment was cancelled or failed',
              isDark: isDark,
              valueColor: Colors.red[600],
              isSmallScreen: isSmallScreen,
              isTinyScreen: isTinyScreen,
            ),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: _formatDateTime(DateTime.now()),
              isDark: isDark,
              isSmallScreen: isSmallScreen,
              isTinyScreen: isTinyScreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
    bool isHighlight = false,
    bool isSmallScreen = false,
    bool isTinyScreen = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isTinyScreen ? 6 : (isSmallScreen ? 8 : 10)),
          decoration: BoxDecoration(
            color: (valueColor ?? AppTheme.primaryLight).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
            color: valueColor ?? AppTheme.primaryLight,
          ),
        ),
        SizedBox(width: isTinyScreen ? 10 : (isSmallScreen ? 12 : 14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTinyScreen ? 10 : (isSmallScreen ? 11 : 12),
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTinyScreen ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight
                      ? (isTinyScreen ? 16 : (isSmallScreen ? 18 : 20))
                      : (isTinyScreen ? 12 : (isSmallScreen ? 13 : 14)),
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ??
                      (isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasedCourses(bool isDark, bool isSmallScreen, bool isTinyScreen) {
    final courses = widget.purchasedCourses ?? [];
    final maxCoursesToShow = isTinyScreen ? 2 : (isSmallScreen ? 3 : courses.length);
    final coursesToShow = courses.take(maxCoursesToShow).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: AppTheme.primaryLight,
              size: isTinyScreen ? 18 : (isSmallScreen ? 20 : 22),
            ),
            SizedBox(width: isTinyScreen ? 6 : 8),
            Expanded(
              child: Text(
                'Your Courses (${courses.length})',
                style: TextStyle(
                  fontSize: isTinyScreen ? 14 : (isSmallScreen ? 15 : 16),
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
        ...coursesToShow.map((course) => _buildCourseCard(course, isDark, isSmallScreen, isTinyScreen)).toList(),
        if (courses.length > maxCoursesToShow)
          Padding(
            padding: EdgeInsets.only(top: isTinyScreen ? 4 : 8),
            child: Text(
              '+${courses.length - maxCoursesToShow} more courses',
              style: TextStyle(
                fontSize: isTinyScreen ? 10 : 11,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(dynamic course, bool isDark, bool isSmallScreen, bool isTinyScreen) {
    final imageSize = isTinyScreen ? 40.0 : (isSmallScreen ? 50.0 : 55.0);

    return Container(
      margin: EdgeInsets.only(bottom: isTinyScreen ? 6 : (isSmallScreen ? 8 : 10)),
      padding: EdgeInsets.all(isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              course.thumbnailUrl,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: imageSize,
                height: imageSize,
                color: Colors.grey[300],
                child: Icon(Icons.ondemand_video_rounded, size: imageSize * 0.5),
              ),
            ),
          ),
          SizedBox(width: isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseTitle,
                  style: TextStyle(
                    fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 13),
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isTinyScreen ? 2 : 4),
                Text(
                  'by ${course.instructorName}',
                  style: TextStyle(
                    fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : 11),
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green[600],
            size: isTinyScreen ? 18 : (isSmallScreen ? 20 : 22),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, bool isSmallScreen, bool isTinyScreen) {
    final verticalPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
    final fontSize = isTinyScreen ? 13.0 : (isSmallScreen ? 14.0 : 15.0);
    final iconSize = isTinyScreen ? 18.0 : (isSmallScreen ? 20.0 : 22.0);

    if (widget.isSuccess) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary: Start Learning
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_filled_rounded, size: iconSize),
                  SizedBox(width: isTinyScreen ? 6 : 8),
                  Flexible(
                    child: Text(
                      isTinyScreen ? 'Start Learning' : 'Start Learning Now',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTinyScreen ? 8 : 10),
          // Secondary: View My Courses
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _navigateToMyCourses,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                side: BorderSide(color: AppTheme.primaryLight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'View My Courses',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: isTinyScreen ? 8 : 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _navigateToHome,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Go to Home',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _navigateToCourse() {
    // Clear cart
    context.read<CartBloc>().add(const LoadCartWithFreshData());

    if (widget.purchasedCourses != null &&
        widget.purchasedCourses!.isNotEmpty) {
      final firstCourse = widget.purchasedCourses!.first;

      // Navigate to course, clearing all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => CourseDetailsScreen(
            course: {
              'id': firstCourse.courseId,
              'title': firstCourse.courseTitle,
              'description': firstCourse.courseTitle,
              'instructor': firstCourse.instructorName,
              'price': firstCourse.price,
              'thumbnailUrl': firstCourse.thumbnailUrl,
              'rating': 0.0,
              'totalRatings': 0,
              'duration': '0',
              'level': 'Beginner',
              'language': 'English',
              'category': 'General',
              'isPremium': false,
              'subscriptionPeriod': firstCourse.subscriptionPeriod,
              'accessEndDate': firstCourse.accessEndDate.toIso8601String(),
            },
          ),
        ),
        (route) => route.isFirst, // Keep only the first route (home/main)
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToMyCourses() {
    // Clear cart
    context.read<CartBloc>().add(const LoadCartWithFreshData());

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MyPurchasesScreen(),
      ),
      (route) => route.isFirst,
    );
  }

  void _navigateToHome() {
    // Clear cart
    context.read<CartBloc>().add(const LoadCartWithFreshData());

    // Pop all routes except the first one
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _retryPayment() {
    // Go back to payment screen
    Navigator.of(context).pop();
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }
}
