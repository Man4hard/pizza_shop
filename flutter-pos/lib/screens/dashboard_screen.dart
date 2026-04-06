import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sale_record.dart';
import '../services/database_service.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  List<TopProduct> _topProducts = [];
  List<HourlySales> _hourlySales = [];
  bool _loading = true;
  String? _error;

  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        DatabaseService.getDashboardSummary(),
        DatabaseService.getTopProducts(),
        DatabaseService.getHourlySales(),
      ]);
      setState(() {
        _summary = results[0] as DashboardSummary;
        _topProducts = results[1] as List<TopProduct>;
        _hourlySales = results[2] as List<HourlySales>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError(s)
              : _buildContent(s),
    );
  }

  Widget _buildError(s) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: Text(s.retry)),
      ],
    ),
  );

  Widget _buildContent(s) {
    final summary = _summary!;
    final isWide = Breakpoints.isWide(MediaQuery.of(context).size.width);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(s),
            const SizedBox(height: 24),
            _buildStatCards(summary, s, columns: isWide ? 4 : 2),
            const SizedBox(height: 28),
            _buildOrderStatusRow(summary, s),
            const SizedBox(height: 28),
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hourlySales.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(s.salesTodayByHour),
                          const SizedBox(height: 16),
                          _buildHourlyChart(),
                        ],
                      ),
                    ),
                  if (_hourlySales.isNotEmpty && _topProducts.isNotEmpty)
                    const SizedBox(width: 24),
                  if (_topProducts.isNotEmpty)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(s.topSellingProducts),
                          const SizedBox(height: 16),
                          _buildTopProductsTable(s),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              if (_hourlySales.isNotEmpty) ...[
                _buildSectionTitle(s.salesTodayByHour),
                const SizedBox(height: 16),
                _buildHourlyChart(),
                const SizedBox(height: 28),
              ],
              if (_topProducts.isNotEmpty) ...[
                _buildSectionTitle(s.topSellingProducts),
                const SizedBox(height: 16),
                _buildTopProductsTable(s),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(s) => Row(
    children: [
      Text(
        s.dashboard,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
        tooltip: s.retry,
      ),
    ],
  );

  Widget _buildStatCards(DashboardSummary s, ls, {int columns = 2}) => GridView.count(
    crossAxisCount: columns,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.8,
    children: [
      StatCard(
        title: ls.todaysRevenue,
        value: _currency.format(s.totalRevenue),
        icon: Icons.payments_rounded,
        iconColor: AppColors.success,
        iconBg: AppColors.success.withOpacity(0.12),
      ),
      StatCard(
        title: ls.totalOrders,
        value: s.totalOrders.toString(),
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.accent,
        iconBg: AppColors.accent.withOpacity(0.12),
      ),
    ],
  );

  Widget _buildOrderStatusRow(DashboardSummary s, ls) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statusPill(ls.pending, s.pendingOrders, AppColors.warning),
        _statusPill(ls.completed, s.completedOrders, AppColors.success),
        _statusPill(ls.cancelled, s.cancelledOrders, AppColors.error),
      ],
    ),
  );

  Widget _statusPill(String label, int count, Color color) => Column(
    children: [
      Text(
        count.toString(),
        style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ],
  );

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
  );

  Widget _buildHourlyChart() {
    final maxY = _hourlySales.map((h) => h.totalSales).fold<double>(0, (a, b) => a > b ? a : b);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: _hourlySales.map((h) => BarChartGroupData(
            x: h.hour,
            barRods: [
              BarChartRodData(
                toY: h.totalSales,
                color: AppColors.primary,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          )).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}h',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTopProductsTable(s) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      children: _topProducts.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          color: i == 0 ? AppColors.accent : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p.productName,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                  Text('×${p.quantitySold}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text(
                    _currency.format(p.revenue),
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (i < _topProducts.length - 1) const Divider(height: 1),
          ],
        );
      }).toList(),
    ),
  );
}
