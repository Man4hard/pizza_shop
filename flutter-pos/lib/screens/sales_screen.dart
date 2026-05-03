import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_record.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

enum _Period { daily, weekly, monthly }

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with WidgetsBindingObserver {
  List<SaleRecord> _sales = [];
  bool _loading = true;
  String? _error;
  _Period _period = _Period.daily;

  // Track the date when the screen was last loaded so we can detect day changes
  late DateTime _loadedOn;

  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('hh:mm a');
  final _monthFormat = DateFormat('MMMM yyyy');

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadedOn = _todayOnly();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the app comes back to the foreground, check if the date changed.
  /// If it did and we are in Daily mode, reload so the screen shows the new
  /// (empty) day automatically.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _todayOnly();
      if (_period == _Period.daily && !_sameDay(_loadedOn, today)) {
        _loadedOn = today;
        _load();
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _todayOnly() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the [start, end] date range for the currently selected period.
  DateTimeRange _rangeFor(_Period p) {
    final today = _todayOnly();
    switch (p) {
      case _Period.daily:
        return DateTimeRange(start: today, end: today);
      case _Period.weekly:
        // Week starts on Monday (weekday == 1)
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: monday, end: today);
      case _Period.monthly:
        final first = DateTime(today.year, today.month, 1);
        return DateTimeRange(start: first, end: today);
    }
  }

  String get _periodSubtitle {
    final r = _rangeFor(_period);
    switch (_period) {
      case _Period.daily:
        return _dateFormat.format(r.start);
      case _Period.weekly:
        return '${_dateFormat.format(r.start)} – ${_dateFormat.format(r.end)}';
      case _Period.monthly:
        return _monthFormat.format(r.start);
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final range = _rangeFor(_period);
      final sales = await DatabaseService.getSales(
        startDate: range.start.toIso8601String(),
        endDate: range.end.toIso8601String(),
      );
      setState(() {
        _sales = sales;
        _loading = false;
        _loadedOn = _todayOnly(); // refresh the tracked date on every load
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _switchPeriod(_Period p) {
    if (_period == p) return;
    setState(() => _period = p);
    _load();
  }

  // ── Derived data ───────────────────────────────────────────────────────────

  double get _totalRevenue => _sales.fold(0.0, (s, r) => s + r.total);

  int get _totalOrders => _sales.length;

  Map<String, double> get _paymentBreakdown {
    final map = <String, double>{};
    for (final s in _sales) {
      map[s.paymentMethod] = (map[s.paymentMethod] ?? 0) + s.total;
    }
    return map;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales History',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _periodSubtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary),
              tooltip: 'Refresh',
            ),
          ],
        ),
      );

  Widget _buildPeriodBar() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            _chip(_Period.daily, 'Daily'),
            const SizedBox(width: 8),
            _chip(_Period.weekly, 'Weekly'),
            const SizedBox(width: 8),
            _chip(_Period.monthly, 'Monthly'),
          ],
        ),
      );

  Widget _chip(_Period p, String label) {
    final selected = _period == p;
    return GestureDetector(
      onTap: () => _switchPeriod(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_sales.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = Breakpoints.isWide(constraints.maxWidth);
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildSummaryCard()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: isWide
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildSummaryCard() => Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.20)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Revenue',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                      Text(
                        _currency.format(_totalRevenue),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Orders',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                      Text(
                        _totalOrders.toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_paymentBreakdown.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: _paymentBreakdown.entries
                      .map(
                        (e) => Expanded(
                          child: Column(
                            children: [
                              Text(
                                _pmLabel(e.key),
                                style: TextStyle(
                                  color: _pmColor(e.key),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currency.format(e.value),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildEmpty() {
    final msgs = {
      _Period.daily: ('No sales today', 'Sales made today will appear here.\nThe screen resets automatically each new day.'),
      _Period.weekly: ('No sales this week', 'Sales made this week will appear here.'),
      _Period.monthly: ('No sales this month', 'Sales made this month will appear here.'),
    };
    final (title, subtitle) = msgs[_period]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTile(SaleRecord sale) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _pmColor(sale.paymentMethod).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _pmLabel(sale.paymentMethod),
                style: TextStyle(
                  color: _pmColor(sale.paymentMethod),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    [
                      _dateFormat.format(sale.soldAt.toLocal()),
                      _timeFormat.format(sale.soldAt.toLocal()),
                      if (sale.tableNumber != null)
                        'Table ${sale.tableNumber}',
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
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
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.itemCount} items',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _pmLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'digital':
        return 'Digital';
      default:
        return method;
    }
  }

  Color _pmColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'card':
        return AppColors.accent;
      case 'digital':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}
