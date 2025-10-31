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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Animated Icon/Lottie
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildAnimatedIcon(isDark),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.isSuccess ? 'Payment Successful!' : 'Payment Failed',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: widget.isSuccess
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.isSuccess
                            ? 'Your courses are ready to access!'
                            : 'Something went wrong with your payment',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Details Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildDetailsCard(isDark),
                    ),

                    const SizedBox(height: 32),

                    // Purchased Courses (if success)
                    if (widget.isSuccess && widget.purchasedCourses != null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildPurchasedCourses(isDark),
                      ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildActionButtons(isDark),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark) {
    if (widget.isSuccess) {
      // You can use Lottie animation here if you have the asset
      // return Lottie.asset('assets/success.json', width: 200, height: 200);

      // For now, using a beautiful custom icon
      return Container(
        width: 150,
        height: 150,
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
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 80,
        ),
      );
    } else {
      return Container(
        width: 150,
        height: 150,
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
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Icon(
          Icons.error_rounded,
          color: Colors.white,
          size: 80,
        ),
      );
    }
  }

  Widget _buildDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.surfaceDark, AppTheme.surfaceDark]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Amount Paid',
              value: '₹${widget.amount?.toStringAsFixed(0) ?? '0'}',
              isDark: isDark,
              valueColor: Colors.green[600],
              isHighlight: true,
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Date & Time',
              value: _formatDateTime(DateTime.now()),
              isDark: isDark,
            ),
          ] else ...[
            _buildDetailRow(
              icon: Icons.error_outline_rounded,
              label: 'Error',
              value: widget.errorMessage ?? 'Payment was cancelled or failed',
              isDark: isDark,
              valueColor: Colors.red[600],
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: _formatDateTime(DateTime.now()),
              isDark: isDark,
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (valueColor ?? AppTheme.primaryLight).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: valueColor ?? AppTheme.primaryLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 20 : 15,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ??
                      (isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasedCourses(bool isDark) {
    final courses = widget.purchasedCourses ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school_rounded,
              color: AppTheme.primaryLight,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Your Courses (${courses.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...courses.map((course) => _buildCourseCard(course, isDark)).toList(),
      ],
    );
  }

  Widget _buildCourseCard(dynamic course, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              course.thumbnailUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.ondemand_video_rounded),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${course.instructorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    if (widget.isSuccess) {
      return Column(
        children: [
          // Primary: Start Learning
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_circle_filled_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Start Learning Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary: View My Courses
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _navigateToMyCourses,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primaryLight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View My Courses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tertiary: Go to Home
          TextButton(
            onPressed: _navigateToHome,
            child: Text(
              'Go to Home',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _navigateToHome,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontSize: 16,
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
