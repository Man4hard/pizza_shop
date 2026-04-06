import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class BillDialog extends StatelessWidget {
  final Order order;

  const BillDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  'assets/images/receipt_final.png',
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Main Khushab Road, Adda Chandna, Dist. Jhang',
                style: TextStyle(color: Colors.black54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              const Text(
                '0313-7258091 | 0313-7258113',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 20),
              _dottedDivider(),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt #${order.orderNumber}',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(order.completedAt?.toLocal() ?? order.createdAt.toLocal()),
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
              if (order.customerName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Customer: ', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(order.customerName!, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              if (order.tableNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Table: ', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(order.tableNumber!, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _dottedDivider(),
              const SizedBox(height: 12),
              // Items
              if (order.items.isNotEmpty)
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ),
                      Text(
                        currency.format(item.subtotal),
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                )).toList(),
              const SizedBox(height: 8),
              _dottedDivider(),
              const SizedBox(height: 12),
              // Totals
              if ((order.discount) > 0) ...[
                _totalRow('Discount', '-${currency.format(order.discount)}', color: Colors.green),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      currency.format(order.total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _dottedDivider(),
              const SizedBox(height: 14),
              const Text(
                'شکریہ! دوبارہ تشریف لائیں',
                style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Thank you for visiting Ahmed Fast Food!',
                style: TextStyle(color: Colors.black38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Print feature coming soon!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dottedDivider() => Row(
    children: List.generate(
      40,
      (i) => Expanded(
        child: Container(
          height: 1,
          color: i.isEven ? Colors.black12 : Colors.transparent,
        ),
      ),
    ),
  );

  Widget _totalRow(String label, String value, {Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      Text(
        value,
        style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ],
  );
}
