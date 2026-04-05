import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sale_record.dart';
import '../services/database_service.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildContent() {
    final s = _summary!;
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatCards(s, columns: isWide ? 4 : 2),
            const SizedBox(height: 28),
            _buildOrderStatusRow(s),
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
                          _buildSectionTitle('Sales Today by Hour'),
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
                          _buildSectionTitle('Top Selling Products'),
                          const SizedBox(height: 16),
                          _buildTopProducts(),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              if (_hourlySales.isNotEmpty) ...[
                _buildSectionTitle('Sales Today by Hour'),
                const SizedBox(height: 16),
                _buildHourlyChart(),
                const SizedBox(height: 28),
              ],
              if (_topProducts.isNotEmpty) ...[
                _buildSectionTitle('Top Selling Products'),
                const SizedBox(height: 16),
                _buildTopProducts(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_greeting()}, Chef!',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildStatCards(DashboardSummary s, {int columns = 2}) => GridView.count(
    crossAxisCount: columns,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: columns == 4 ? 2.4 : 2.0,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      StatCard(
        title: "Today's Revenue",
        value: _currency.format(s.totalSalesToday),
        icon: Icons.attach_money_rounded,
        iconColor: AppColors.success,
        iconBg: AppColors.successBg,
      ),
      StatCard(
        title: 'Total Orders',
        value: s.totalOrdersToday.toString(),
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.primary,
        iconBg: const Color(0xFF2D0C0B),
      ),
      StatCard(
        title: 'Avg Order Value',
        value: _currency.format(s.averageOrderValue),
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.accent,
        iconBg: AppColors.warningBg,
      ),
      StatCard(
        title: 'Active Orders',
        value: s.pendingOrders.toString(),
        icon: Icons.pending_actions_rounded,
        iconColor: AppColors.primaryLight,
        iconBg: const Color(0xFF2D0C0B),
      ),
    ],
  );

  Widget _buildOrderStatusRow(DashboardSummary s) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        _statusPill('Pending', s.pendingOrders, AppColors.warning),
        const Spacer(),
        _statusPill('Completed', s.completedOrders, AppColors.success),
        const Spacer(),
        _statusPill('Cancelled', s.cancelledOrders, AppColors.error),
      ],
    ),
  );

  Widget _statusPill(String label, int count, Color color) => Column(
    children: [
      Text(count.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ],
  );

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _buildHourlyChart() => Container(
    height: 180,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final h = val.toInt();
                if (h % 3 != 0) return const SizedBox.shrink();
                return Text('${h}h', style: const TextStyle(color: AppColors.textMuted, fontSize: 11));
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: _hourlySales.map((h) => BarChartGroupData(
          x: h.hour,
          barRods: [
            BarChartRodData(
              toY: h.sales,
              color: AppColors.primary,
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        )).toList(),
      ),
    ),
  );

  Widget _buildTopProducts() => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
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
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                  Text('×${p.quantitySold}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text(
                    _currency.format(p.revenue),
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w600),
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
