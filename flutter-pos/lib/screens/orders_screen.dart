import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/bill_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'pending';

  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final _timeFormat = DateFormat('hh:mm a');
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      final statuses = ['pending', 'completed', 'cancelled'];
      if (!_tabs.indexIsChanging) {
        setState(() => _selectedStatus = statuses[_tabs.index]);
        _loadOrders();
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await DatabaseService.getOrders(status: _selectedStatus);
      setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _viewBill(Order order) async {
    try {
      final detail = await DatabaseService.getOrder(order.id);
      if (mounted) {
        await showDialog(context: context, builder: (_) => BillDialog(order: detail));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Error'}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Order', style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Cancel order ${order.orderNumber}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: Text('No', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseService.cancelOrder(order.id);
        _loadOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'Error'}: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: AppColors.surface,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Orders',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _orders.isEmpty
                  ? Center(
                      child: Text('No orders found',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 16)))
                  : LayoutBuilder(
                      builder: (_, constraints) {
                        final isWide = Breakpoints.isWide(constraints.maxWidth);
                        if (isWide) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.4,
                            ),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                        );
                      },
                    ),
    );
  }

  Widget _buildOrderCard(Order order) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.orderNumber,
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusLabel(order.status),
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _timeFormat.format(order.createdAt.toLocal()),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              _currency.format(order.total),
              style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (order.status == 'completed')
              TextButton.icon(
                onPressed: () => _viewBill(order),
                icon: const Icon(Icons.receipt_outlined, size: 16),
                label: Text('View Bill'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            if (order.status == 'pending')
              TextButton.icon(
                onPressed: () => _cancelOrder(order),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
          ],
        ),
      ],
    ),
  );

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.warning;
    }
  }
}
