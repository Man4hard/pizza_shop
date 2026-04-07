import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sale_record.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

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

  double get _totalRevenue => _sales.fold(0, (sum, s) => sum + s.total);

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
                                final isWide = Breakpoints.isWide(constraints.maxWidth);
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

  Widget _buildHeader() => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
    child: Row(
      children: [
        Text(
          'Sales History',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(
            _dateRange != null
                ? '${_dateFormat.format(_dateRange!.start)} – ${_dateFormat.format(_dateRange!.end)}'
                : 'Filter by date',
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
        ),
        if (_dateRange != null)
          IconButton(
            onPressed: () { setState(() => _dateRange = null); _load(); },
            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
            tooltip: 'Clear filter',
          ),
      ],
    ),
  );

  Widget _buildSummary() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Revenue', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    _currency.format(_totalRevenue),
                    style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Spacer(),
              ..._paymentBreakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_pmLabel(e.key), style: TextStyle(color: _pmColor(e.key), fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(_currency.format(e.value), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text('No sales yet', style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
      ],
    ),
  );

  Widget _buildSaleTile(SaleRecord sale) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _pmColor(sale.paymentMethod).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _pmLabel(sale.paymentMethod, s),
            style: TextStyle(color: _pmColor(sale.paymentMethod), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sale.orderNumber,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  _dateFormat.format(sale.soldAt.toLocal()),
                  _timeFormat.format(sale.soldAt.toLocal()),
                  if (sale.tableNumber != null) '${'Table'} ${sale.tableNumber}',
                ].join(' · '),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(sale.total),
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              '${sale.itemCount} ${'items'}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  String _pmLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return 'Cash';
      case 'card': return 'Card';
      case 'digital': return 'Digital';
      default: return method;
    }
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
