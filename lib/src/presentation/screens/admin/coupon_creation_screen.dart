import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/coupon/coupon_bloc.dart';
import '../../../core/bloc/coupon/coupon_event.dart';
import '../../../core/bloc/coupon/coupon_state.dart';
import '../../../core/bloc/course/course_bloc.dart';
import '../../../core/bloc/course/course_event.dart';
import '../../../core/bloc/course/course_state.dart';
import '../../widgets/common/widgets.dart';

class CouponCreationScreen extends StatefulWidget {
  final Map<String, dynamic>? couponToEdit;

  const CouponCreationScreen({
    super.key,
    this.couponToEdit,
  });

  @override
  State<CouponCreationScreen> createState() => _CouponCreationScreenState();
}

class _CouponCreationScreenState extends State<CouponCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  
  DateTime? _validUntil;
  String? _selectedCourseId;
  String? _selectedCourseTitle;
  bool _isActive = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (widget.couponToEdit != null) {
      _loadCouponData();
    }
  }

  void _loadCourses() {
    context.read<CourseBloc>().add(const LoadCourses());
  }

  void _loadCouponData() {
    final coupon = widget.couponToEdit!;
    _codeController.text = coupon['code'] ?? '';
    _discountController.text = coupon['discountPercentage']?.toString() ?? '';
    _selectedCourseId = coupon['courseId'];
    _selectedCourseTitle = coupon['courseTitle'];
    _isActive = coupon['isActive'] ?? true;
    
    final validUntil = coupon['validUntil'];
    if (validUntil != null) {
      _validUntil = validUntil.toDate();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CouponBloc, CouponState>(
      listener: (context, state) {
        if (state is CouponCreated || state is CouponUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.couponToEdit != null 
                    ? 'Coupon updated successfully!' 
                    : 'Coupon created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is CouponError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.couponToEdit != null ? 'Edit Coupon' : 'Create Coupon'),
          backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
          foregroundColor: isDark ? AppTheme.textPrimaryDark : Colors.white,
          actions: [
            TextButton(
              onPressed: _saveCoupon,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coupon Code
                _buildCouponCodeSection(isDark),
                const SizedBox(height: 24),
                
                // Discount Percentage
                _buildDiscountSection(isDark),
                const SizedBox(height: 24),
                
                // Course Selection
                _buildCourseSelectionSection(isDark),
                const SizedBox(height: 24),
                
                // Valid Until
                _buildValidUntilSection(isDark),
                const SizedBox(height: 24),
                
                // Active Toggle
                _buildActiveToggle(isDark),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveCoupon,
          backgroundColor: AppTheme.primaryLight,
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text(
            widget.couponToEdit != null ? 'Update Coupon' : 'Create Coupon',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCodeSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coupon Code',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Coupon Code',
              hint: 'Enter unique coupon code (e.g., SAVE20)',
              controller: _codeController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a coupon code';
                }
                if (value.trim().length < 3) {
                  return 'Coupon code must be at least 3 characters';
                }
                return null;
              },
              prefixIcon: const Icon(Icons.local_offer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discount Percentage',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Discount %',
              hint: 'Enter discount percentage (e.g., 20)',
              controller: _discountController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter discount percentage';
                }
                final discount = int.tryParse(value.trim());
                if (discount == null || discount <= 0 || discount > 100) {
                  return 'Please enter a valid percentage (1-100)';
                }
                return null;
              },
              prefixIcon: const Icon(Icons.percent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelectionSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Selection',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<CourseBloc, CourseState>(
              builder: (context, state) {
                if (state is CourseLoaded) {
                  _courses = state.courses;
                }
                
                return CustomTextField(
                  label: 'Select Course',
                  hint: _selectedCourseTitle ?? 'Choose a course for this coupon',
                  readOnly: true,
                  onTap: _showCourseSelection,
                  prefixIcon: const Icon(Icons.video_library),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  validator: (value) {
                    if (_selectedCourseId == null) {
                      return 'Please select a course';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidUntilSection(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validity Period',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Valid Until',
              hint: _validUntil != null 
                  ? '${_validUntil!.day}/${_validUntil!.month}/${_validUntil!.year}'
                  : 'Select expiry date',
              readOnly: true,
              onTap: _selectValidUntil,
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              validator: (value) {
                if (_validUntil == null) {
                  return 'Please select validity date';
                }
                if (_validUntil!.isBefore(DateTime.now())) {
                  return 'Validity date cannot be in the past';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggle(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isActive ? Icons.check_circle : Icons.cancel,
              color: _isActive ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Coupon',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isActive 
                        ? 'This coupon is currently active and can be used'
                        : 'This coupon is inactive and cannot be used',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: AppTheme.primaryLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCourseSelectionBottomSheet(),
    );
  }

  Widget _buildCourseSelectionBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Select Course',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (_courses.isEmpty)
                  const Text('No courses available')
                else
                  ..._courses.map((course) => ListTile(
                    leading: const Icon(Icons.video_library),
                    title: Text(course['title'] ?? 'Untitled Course'),
                    onTap: () {
                      setState(() {
                        _selectedCourseId = course['id'];
                        _selectedCourseTitle = course['title'];
                      });
                      Navigator.pop(context);
                    },
                  )).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectValidUntil() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _validUntil = selectedDate;
      });
    }
  }

  void _saveCoupon() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final couponData = {
      'code': _codeController.text.trim().toUpperCase(),
      'discountPercentage': int.parse(_discountController.text.trim()),
      'courseId': _selectedCourseId,
      'courseTitle': _selectedCourseTitle,
      'validUntil': Timestamp.fromDate(_validUntil!),
      'isActive': _isActive,
    };

    if (widget.couponToEdit != null) {
      context.read<CouponBloc>().add(UpdateCoupon(
        couponId: widget.couponToEdit!['id'],
        couponData: couponData,
      ));
    } else {
      context.read<CouponBloc>().add(CreateCoupon(couponData: couponData));
    }
  }
}
