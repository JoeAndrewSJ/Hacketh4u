import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/bloc/payment/payment_bloc.dart';
import '../../../core/bloc/payment/payment_event.dart';
import '../../../core/bloc/payment/payment_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/payment_model.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(const LoadPaymentHistory());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Purchases',
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
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentHistoryLoaded) {
            if (state.payments.isEmpty) {
              return _buildEmptyState(isDark);
            }
            return _buildPurchasesList(state.payments, isDark);
          } else if (state is PaymentError) {
            return _buildErrorState(state.error, isDark);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Purchases Yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your course purchases will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Purchases',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PaymentBloc>().add(const LoadPaymentHistory());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesList(List<PaymentModel> payments, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PaymentBloc>().add(const LoadPaymentHistory());
      },
      color: AppTheme.primaryLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return _buildPurchaseCard(payment, isDark);
        },
      ),
    );
  }

  Widget _buildPurchaseCard(PaymentModel payment, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800.withOpacity(0.2) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryLight.withOpacity(0.1)
                  : AppTheme.primaryLight.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight,
                        AppTheme.primaryLight.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(payment.paymentStatus),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${payment.courses.length} Course${payment.courses.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.paymentStatus).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(payment.paymentStatus).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              payment.paymentStatus.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(payment.paymentStatus),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(payment.paymentDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${payment.finalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.h3.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    if (payment.discountAmount > 0)
                      Text(
                        '₹${payment.totalAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Courses List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchased Courses',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...payment.courses.map((course) => _buildCourseItem(course, isDark)),

                // Payment Details Section
                const SizedBox(height: 16),
                _buildPaymentInfoSection(payment, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(PaymentCourse course, bool isDark) {
    final accessPeriod = course.subscriptionPeriod == 0
        ? 'Lifetime Access'
        : '${course.subscriptionPeriod} Days Access';

    final accessEndDate = course.subscriptionPeriod == 0
        ? 'Never Expires'
        : 'Expires: ${course.accessEndDate.day}/${course.accessEndDate.month}/${course.accessEndDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              course.thumbnailUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLight.withOpacity(0.3),
                        AppTheme.primaryLight.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: AppTheme.primaryLight,
                    size: 30,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Course Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${course.instructorName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            accessPeriod,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (course.subscriptionPeriod > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    accessEndDate,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${course.price.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (course.originalPrice > course.price)
                Text(
                  '₹${course.originalPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection(PaymentModel payment, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundDark
            : AppTheme.primaryLight.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withOpacity(0.3)
              : AppTheme.primaryLight.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                size: 18,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Information',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInfoRow('Total Amount', '₹${payment.totalAmount.toStringAsFixed(0)}', isDark),
          if (payment.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              'Discount ${payment.couponCode != null ? "(${payment.couponCode})" : ""}',
              '-₹${payment.discountAmount.toStringAsFixed(0)}',
              isDark,
              valueColor: Colors.green,
            ),
          ],
          const SizedBox(height: 6),
          Container(
            height: 1,
            color: isDark ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade200,
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Final Amount',
            '₹${payment.finalAmount.toStringAsFixed(0)}',
            isDark,
            isHighlight: true,
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Payment Method', payment.paymentMethod, isDark),

          if (payment.razorpayPaymentId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    payment.razorpayPaymentId!,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isHighlight = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            fontSize: isHighlight ? 14 : 13,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? (isHighlight
                ? AppTheme.primaryLight
                : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 15 : 13,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
