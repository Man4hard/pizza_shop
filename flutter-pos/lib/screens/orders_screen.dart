import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static const _statuses = ['pending', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    _loadOrders();
  }

  void _onTabChanged() {
    // _tabs.index is updated immediately when a tab is tapped,
    // so we reload whenever the index differs from what we have loaded.
    final newStatus = _statuses[_tabs.index];
    if (newStatus != _selectedStatus) {
      setState(() => _selectedStatus = newStatus);
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await DatabaseService.getOrders(status: _selectedStatus);
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Complete order ─────────────────────────────────────────────────────────

  Future<void> _completeOrder(Order order) async {
    final result = await _showPaymentDialog(order);
    if (result == null) return;

    try {
      final completed = await DatabaseService.completeOrder(
        order.id,
        result['method']!,
        discount: double.tryParse(result['discount'] ?? '0') ?? 0,
      );
      _loadOrders();
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => BillDialog(order: completed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<Map<String, String>?> _showPaymentDialog(Order order) async {
    String selectedMethod = 'cash';
    final discountCtrl = TextEditingController(text: '0');

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complete Order',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(order.orderNumber,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order Total',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      _currency.format(order.total),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Payment method
              const Text('Payment Method',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pmButton(ctx, setDlgState, 'cash', 'Cash',
                      Icons.payments_rounded, selectedMethod,
                      (v) => selectedMethod = v),
                  const SizedBox(width: 8),
                  _pmButton(ctx, setDlgState, 'card', 'Card',
                      Icons.credit_card_rounded, selectedMethod,
                      (v) => selectedMethod = v),
                  const SizedBox(width: 8),
                  _pmButton(ctx, setDlgState, 'digital', 'Digital',
                      Icons.phone_android_rounded, selectedMethod,
                      (v) => selectedMethod = v),
                ],
              ),
              const SizedBox(height: 16),
              // Discount
              TextField(
                controller: discountCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Discount (Rs.)',
                  prefixIcon: const Icon(Icons.discount_outlined,
                      color: AppColors.textMuted, size: 18),
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, {
                'method': selectedMethod,
                'discount': discountCtrl.text,
              }),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Complete & Print Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pmButton(
    BuildContext ctx,
    StateSetter setDlgState,
    String value,
    String label,
    IconData icon,
    String selected,
    void Function(String) onSelect,
  ) {
    final isSelected = selected == value;
    final color = value == 'cash'
        ? AppColors.success
        : value == 'card'
            ? AppColors.accent
            : AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setDlgState(() => onSelect(value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancel order ───────────────────────────────────────────────────────────

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Order',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Cancel order ${order.orderNumber}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('No',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
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
            SnackBar(
                content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  // ── View bill ──────────────────────────────────────────────────────────────

  Future<void> _viewBill(Order order) async {
    try {
      final detail = await DatabaseService.getOrder(order.id);
      if (mounted) {
        await showDialog(
            context: context, builder: (_) => BillDialog(order: detail));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
                      const Text(
                        'Orders',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? _buildEmpty()
                  : LayoutBuilder(
                      builder: (_, constraints) {
                        final isWide =
                            Breakpoints.isWide(constraints.maxWidth);
                        if (isWide) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.0,
                            ),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) =>
                                _buildOrderCard(_orders[i]),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _buildOrderCard(_orders[i]),
                        );
                      },
                    ),
    );
  }

  Widget _buildEmpty() {
    final msgs = {
      'pending': ('No pending orders', 'New orders from the POS will appear here.'),
      'completed': ('No completed orders', 'Completed orders will appear here.'),
      'cancelled': ('No cancelled orders', 'Cancelled orders will appear here.'),
    };
    final (title, subtitle) = msgs[_selectedStatus]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedStatus == 'pending'
                ? Icons.hourglass_empty_rounded
                : _selectedStatus == 'completed'
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
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
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
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
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _timeFormat.format(order.createdAt.toLocal()),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            // Meta row (customer / table)
            if (order.customerName != null || order.tableNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (order.customerName != null) ...[
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(order.customerName!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                  if (order.customerName != null && order.tableNumber != null)
                    const SizedBox(width: 12),
                  if (order.tableNumber != null) ...[
                    const Icon(Icons.table_restaurant_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Table ${order.tableNumber}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Total + actions row
            Row(
              children: [
                Text(
                  _currency.format(order.total),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),

                // Pending: Complete + Cancel buttons
                if (order.status == 'pending') ...[
                  TextButton.icon(
                    onPressed: () => _cancelOrder(order),
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _completeOrder(order),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                // Completed: View Bill button
                if (order.status == 'completed')
                  TextButton.icon(
                    onPressed: () => _viewBill(order),
                    icon: const Icon(Icons.receipt_outlined, size: 16),
                    label: const Text('View Bill'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent),
                  ),
              ],
            ),
          ],
        ),
      );

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
