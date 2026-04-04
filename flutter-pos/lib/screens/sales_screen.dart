import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_record.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<SaleRecord> _sales = [];
  bool _loading = true;
  String? _error;
  DateTimeRange? _dateRange;

  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sales = await DatabaseService.getSales(
        startDate: _dateRange?.start.toIso8601String(),
        endDate: _dateRange?.end.toIso8601String(),
      );
      setState(() { _sales = sales; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _load();
    }
  }

  double get _totalRevenue =>
      _sales.fold(0, (sum, s) => sum + s.total);

  Map<String, double> get _paymentBreakdown {
    final map = <String, double>{};
    for (final sale in _sales) {
      map[sale.paymentMethod] = (map[sale.paymentMethod] ?? 0) + sale.total;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : _sales.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: LayoutBuilder(
                              builder: (_, constraints) {
                                final isWide = constraints.maxWidth >= 700;
                                return CustomScrollView(
                                  slivers: [
                                    SliverToBoxAdapter(child: _buildSummary()),
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                      sliver: isWide
                                          ? SliverGrid(
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing: 16,
                                                mainAxisSpacing: 0,
                                                childAspectRatio: 3.2,
                                              ),
                                              delegate: SliverChildBuilderDelegate(
                                                (_, i) => _buildSaleTile(_sales[i]),
                                                childCount: _sales.length,
                                              ),
                                            )
                                          : SliverList(
                                              delegate: SliverChildBuilderDelegate(
                                                (_, i) => _buildSaleTile(_sales[i]),
                                                childCount: _sales.length,
                                              ),
                                            ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => SafeArea(
    bottom: false,
    child: Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    child: Row(
      children: [
        const Text(
          'Sales History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
          label: Text(
            _dateRange != null
                ? '${_dateFormat.format(_dateRange!.start)} – ${_dateFormat.format(_dateRange!.end)}'
                : 'All Time',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        if (_dateRange != null)
          IconButton(
            onPressed: () {
              setState(() => _dateRange = null);
              _load();
            },
            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
          ),
      ],
    ),
  ),
  );

  Widget _buildSummary() {
    final breakdown = _paymentBreakdown;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D0E0D), Color(0xFF1A0A09)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Revenue',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _currency.format(_totalRevenue),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_sales.length} transactions',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (breakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                children: breakdown.entries.map((e) => Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currency.format(e.value),
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        _paymentIcon(e.key) + ' ' + e.key.toUpperCase(),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _paymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return '💵';
      case 'card': return '💳';
      case 'digital': return '📱';
      default: return '💰';
    }
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart_outlined, size: 72, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('No sales records', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Complete orders to see records here', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 24),
        if (_dateRange != null)
          OutlinedButton(
            onPressed: () {
              setState(() => _dateRange = null);
              _load();
            },
            child: const Text('Clear filter'),
          ),
      ],
    ),
  );

  Widget _buildSaleTile(SaleRecord sale) {
    final paymentColor = _pmColor(sale.paymentMethod);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paymentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_paymentIcon(sale.paymentMethod), style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.orderNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _dateFormat.format(sale.soldAt.toLocal()),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      _timeFormat.format(sale.soldAt.toLocal()),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (sale.tableNumber != null) ...[
                      const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        'Table ${sale.tableNumber}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(sale.total),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${sale.itemCount} items',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _pmColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return AppColors.success;
      case 'card': return AppColors.accent;
      case 'digital': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }
}
