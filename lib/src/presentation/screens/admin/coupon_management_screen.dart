import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/coupon/coupon_bloc.dart';
import '../../../core/bloc/coupon/coupon_event.dart';
import '../../../core/bloc/coupon/coupon_state.dart';
import '../../widgets/coupon/coupon_card.dart';
import 'coupon_creation_screen.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    context.read<CouponBloc>().add(const LoadCoupons());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CouponBloc, CouponState>(
      listener: (context, state) {
        if (state is CouponsLoaded) {
          setState(() {
            _coupons = state.coupons;
          });
        } else if (state is CouponCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coupon "${state.coupon['code']}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCoupons();
        } else if (state is CouponUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coupon "${state.coupon['code']}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCoupons();
        } else if (state is CouponDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coupon deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCoupons();
        } else if (state is CouponError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<CouponBloc, CouponState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Coupon Management'),
              backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
              foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
              actions: [
                IconButton(
                  onPressed: _loadCoupons,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark ? Colors.purple[800]! : Colors.purple[600]!,
                            isDark ? Colors.purple[700]! : Colors.purple[500]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Coupon Management',
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_coupons.length} coupons • ${_getActiveCoupons()} active',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Coupons List
                    Expanded(
                      child: state.isLoading && _coupons.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : _coupons.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _coupons.length,
                                  itemBuilder: (context, index) {
                                    final coupon = _coupons[index];
                                    return CouponCard(
                                      coupon: coupon,
                                      onEdit: () => _editCoupon(coupon),
                                      onDelete: () => _deleteCoupon(coupon),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),

                // Loading overlay
                if (state.isLoading && _coupons.isNotEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _createCoupon,
              backgroundColor: AppTheme.primaryLight,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Coupon',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No Coupons Yet',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first coupon to start offering discounts',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  int _getActiveCoupons() {
    return _coupons.where((coupon) {
      final isActive = coupon['isActive'] ?? true;
      final validUntil = coupon['validUntil'];
      if (validUntil != null) {
        final validDate = validUntil.toDate();
        return isActive && validDate.isAfter(DateTime.now());
      }
      return isActive;
    }).length;
  }

  void _createCoupon() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CouponCreationScreen(),
      ),
    );
  }

  void _editCoupon(Map<String, dynamic> coupon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CouponCreationScreen(couponToEdit: coupon),
      ),
    );
  }

  void _deleteCoupon(Map<String, dynamic> coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete coupon "${coupon['code']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CouponBloc>().add(DeleteCoupon(couponId: coupon['id']));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
