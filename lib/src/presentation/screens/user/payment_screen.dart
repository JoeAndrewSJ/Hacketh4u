import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_event.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../../core/bloc/cart/cart_bloc.dart';
import '../../../core/bloc/cart/cart_event.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'my_purchases_screen.dart';
import 'course_details_screen.dart';
import 'payment_result_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final double discountAmount;
  final double gstAmount;
  final double finalAmount;
  final Map<String, dynamic>? appliedCoupon;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.discountAmount,
    required this.gstAmount,
    required this.finalAmount,
    this.appliedCoupon,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize payment when screen loads
    context.read<PaymentBloc>().add(InitializePayment(
      cartItems: widget.cartItems,
      totalAmount: widget.totalAmount,
      discountAmount: widget.discountAmount,
      gstAmount: widget.gstAmount,
      finalAmount: widget.finalAmount,
      appliedCoupon: widget.appliedCoupon,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _navigateToPaymentResult(true, state);
          } else if (state is PaymentCompletedNavigateToPurchases) {
            // Handled by PaymentSuccess
          } else if (state is PaymentFailed) {
            _navigateToPaymentResult(false, null, state.error);
          } else if (state is PaymentError) {
            _navigateToPaymentResult(false, null, state.error);
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PaymentInitialized) {
            return _buildPaymentContent(state, isDark);
          } else if (state is PaymentProcessing) {
            return _buildProcessingContent(state, isDark);
          } else if (state is PaymentError) {
            return _buildErrorContent(state.error, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPaymentContent(PaymentInitialized state, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary
          _buildOrderSummary(state.payment, isDark),
          const SizedBox(height: 24),
          
          // Course Details
          _buildCourseDetails(state.payment, isDark),
          const SizedBox(height: 24),
          
          // User Details
          _buildUserDetails(state.payment, isDark),
          const SizedBox(height: 24),
          
          // Payment Button
          _buildPaymentButton(state, isDark),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(dynamic payment, bool isDark) {
    // Calculate effective GST percentage for display
    String gstLabel = 'GST';
    if (payment.gstAmount > 0 && widget.cartItems.isNotEmpty) {
      // Get unique GST percentages from cart items
      final gstPercentages = widget.cartItems
          .map((item) => item['gstPercentage'] as double? ?? 0.0)
          .where((gst) => gst > 0)
          .toSet()
          .toList();

      if (gstPercentages.isNotEmpty) {
        if (gstPercentages.length == 1) {
          // Single GST percentage
          gstLabel = 'GST (${gstPercentages.first.toStringAsFixed(0)}%)';
        } else {
          // Multiple GST percentages - show range
          gstPercentages.sort();
          gstLabel = 'GST (${gstPercentages.first.toStringAsFixed(0)}-${gstPercentages.last.toStringAsFixed(0)}%)';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '₹${payment.totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          
          if (payment.discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                  ),
                ),
                Text(
                  '-₹${payment.discountAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          if (payment.gstAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gstLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  '+₹${payment.gstAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${payment.finalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDetails(dynamic payment, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Details',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          ...payment.courses.map<Widget>((course) => _buildCourseItem(course, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildCourseItem(dynamic course, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTinyScreen = screenWidth < 320;

    final accessPeriod = course.subscriptionPeriod == 0
        ? 'Lifetime'
        : '${course.subscriptionPeriod} Days';

    final accessEndDate = course.subscriptionPeriod == 0
        ? 'Never Expires'
        : '${course.accessEndDate.day}/${course.accessEndDate.month}/${course.accessEndDate.year}';

    final imageSize = isTinyScreen ? 50.0 : (isSmallScreen ? 55.0 : 60.0);
    final titleSize = isTinyScreen ? 13.0 : (isSmallScreen ? 14.0 : 15.0);
    final smallTextSize = isTinyScreen ? 10.0 : (isSmallScreen ? 11.0 : 12.0);
    final priceSize = isTinyScreen ? 14.0 : (isSmallScreen ? 15.0 : 16.0);

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  course.thumbnailUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: imageSize * 0.5,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseTitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      course.instructorName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: smallTextSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                '₹${course.price.toStringAsFixed(0)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: priceSize,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          if (isTinyScreen)
            // Stacked layout for tiny screens
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        accessPeriod,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: smallTextSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        accessEndDate,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: smallTextSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Side-by-side layout for normal screens
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isSmallScreen ? 14 : 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      accessPeriod,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: smallTextSize,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: isSmallScreen ? 14 : 16,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      accessEndDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontSize: smallTextSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(dynamic payment, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Details',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow('Name', payment.userName, isDark),
          _buildDetailRow('Email', payment.userEmail, isDark),
          _buildDetailRow('Phone', payment.userPhone, isDark),
          _buildDetailRow('Payment Date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(PaymentInitialized state, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<PaymentBloc>().add(ProcessPayment(
            payment: state.payment,
            razorpayOptions: state.razorpayOptions,
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Pay ₹${state.payment.finalAmount.toStringAsFixed(0)}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingContent(PaymentProcessing state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Processing Payment...',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the payment in the Razorpay window',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Error',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PaymentBloc>().add(ClearPaymentState());
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentResult(bool isSuccess, PaymentSuccess? successState, [String? errorMessage]) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentResultScreen(
          isSuccess: isSuccess,
          transactionId: successState?.razorpayPaymentId,
          amount: successState?.payment.finalAmount,
          purchasedCourses: successState?.payment.courses,
          errorMessage: errorMessage,
        ),
      ),
    );
  }
}
