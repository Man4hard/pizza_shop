import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double total;

  const PaymentDialog({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'cash';
  double _discount = 0;
  final _discountCtrl = TextEditingController(text: '0');
  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  double get _finalTotal => (widget.total - _discount).clamp(0, double.infinity);

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryRow('Subtotal', widget.subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (10%)', widget.tax),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Discount', style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary, textBaseline: TextBaseline.alphabetic),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      prefixStyle: const TextStyle(color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _discount = double.tryParse(v) ?? 0);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _currency.format(_finalTotal),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _methodOption('cash', '💵', 'Cash'),
                const SizedBox(width: 10),
                _methodOption('card', '💳', 'Card'),
                const SizedBox(width: 10),
                _methodOption('digital', '📱', 'Digital'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, {
                      'method': _method,
                      'discount': _discount,
                    }),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Confirm Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(_currency.format(value), style: const TextStyle(color: AppColors.textSecondary)),
    ],
  );

  Widget _methodOption(String value, String emoji, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _method = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _method == value ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _method == value ? AppColors.primary : AppColors.cardBorder,
            width: _method == value ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _method == value ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
