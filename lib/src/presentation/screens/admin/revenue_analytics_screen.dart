import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/stats/stats_bloc.dart';
import '../../../core/bloc/stats/stats_event.dart';
import '../../../core/bloc/stats/stats_state.dart';
import '../../../core/di/service_locator.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  late StatsBloc _statsBloc;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = 'All Time';

  final List<String> _filterOptions = [
    'All Time',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
    'Last Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _statsBloc = sl<StatsBloc>();
    _statsBloc.add(const LoadAppStats());
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();

      switch (filter) {
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 3 Months':
          _startDate = DateTime(now.year, now.month - 3, 1);
          _endDate = now;
          break;
        case 'Last 6 Months':
          _startDate = DateTime(now.year, now.month - 6, 1);
          _endDate = now;
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
        case 'Last Year':
          _startDate = DateTime(now.year - 1, 1, 1);
          _endDate = DateTime(now.year - 1, 12, 31);
          break;
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
        case 'Custom Range':
          _showDateRangePicker();
          return;
      }
    });
    _statsBloc.add(const RefreshStats());
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryLight,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _statsBloc.add(const RefreshStats());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Analytics'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _statsBloc.add(const RefreshStats());
            },
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _statsBloc,
        child: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            if (state is StatsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppStatsLoaded) {
              return _buildContent(context, state.appStats, isDark);
            } else if (state is StatsError) {
              return _buildErrorState(context, state.message, isDark);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic stats, bool isDark) {
    final filteredRevenue = _getFilteredRevenue(stats.monthlyRevenue);
    final totalRevenue = filteredRevenue.values.fold<double>(0.0, (sum, value) => sum + value);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          _buildFilterSection(isDark),

          // Selected Date Range Display
          if (_startDate != null && _endDate != null)
            _buildDateRangeDisplay(isDark),

          // Total Revenue Card
          _buildTotalRevenueCard(totalRevenue, isDark),

          // Revenue Breakdown
          _buildRevenueBreakdown(filteredRevenue, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.surfaceDark, AppTheme.surfaceDark.withOpacity(0.8)]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.filter_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Filter by Date Range',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _applyFilter(filter);
                  }
                },
                selectedColor: AppTheme.primaryLight,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                elevation: isSelected ? 4 : 0,
                shadowColor: isSelected ? AppTheme.primaryLight.withOpacity(0.5) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.blue[700], size: 20),
            onPressed: () {
              setState(() {
                _selectedFilter = 'All Time';
                _startDate = null;
                _endDate = null;
              });
              _statsBloc.add(const RefreshStats());
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard(double totalRevenue, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.trending_up, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total Revenue',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalRevenue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(Map<String, double> filteredRevenue, bool isDark) {
    if (filteredRevenue.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No revenue data for selected period',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = filteredRevenue.entries.toList()
      ..sort((a, b) => _parseMonthYear(b.key).compareTo(_parseMonthYear(a.key)));

    final maxRevenue = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Revenue Breakdown',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedEntries.map((entry) {
            final month = entry.key;
            final revenue = entry.value;
            final percentage = maxRevenue > 0 ? revenue / maxRevenue : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        month,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '₹${revenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        revenue == maxRevenue ? Colors.green : Colors.orange,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% of max',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Revenue Data',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _statsBloc.add(const LoadAppStats());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getFilteredRevenue(Map<String, double> monthlyRevenue) {
    if (_startDate == null || _endDate == null) {
      return monthlyRevenue;
    }

    final filtered = <String, double>{};
    for (var entry in monthlyRevenue.entries) {
      final monthDate = _parseMonthYear(entry.key);
      if (monthDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          monthDate.isBefore(_endDate!.add(const Duration(days: 1)))) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  DateTime _parseMonthYear(String monthYear) {
    try {
      // Expected format: "Jan 2024" or "January 2024"
      final parts = monthYear.split(' ');
      if (parts.length == 2) {
        final monthNames = {
          'Jan': 1, 'January': 1,
          'Feb': 2, 'February': 2,
          'Mar': 3, 'March': 3,
          'Apr': 4, 'April': 4,
          'May': 5,
          'Jun': 6, 'June': 6,
          'Jul': 7, 'July': 7,
          'Aug': 8, 'August': 8,
          'Sep': 9, 'September': 9,
          'Oct': 10, 'October': 10,
          'Nov': 11, 'November': 11,
          'Dec': 12, 'December': 12,
        };

        final month = monthNames[parts[0]] ?? 1;
        final year = int.tryParse(parts[1]) ?? DateTime.now().year;
        return DateTime(year, month, 1);
      }
    } catch (e) {
      // Fallback to current date if parsing fails
    }
    return DateTime.now();
  }
}
