import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

String _categoryEmoji(String categoryName) {
  final n = categoryName.toLowerCase();
  if (n.contains('deal')) return '🎁';
  if (n.contains('burger') || n.contains('shawarma')) return '🍔';
  if (n.contains('crispy') || n.contains('grilled')) return '🍗';
  return '🍕';
}

class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: inCart
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inCart ? AppColors.primary : AppColors.cardBorder,
            width: inCart ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _categoryEmoji(product.categoryName ?? ''),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (inCart) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓  $quantity in cart',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Grouped product card (one card for all sizes of a pizza) ──────────
class GroupedProductCard extends StatelessWidget {
  final String baseName;
  final List<Product> variants; // sorted S → M → L → XL
  final Map<int, int> cartQuantities; // productId → qty
  final void Function(Product) onVariantSelected;

  const GroupedProductCard({
    super.key,
    required this.baseName,
    required this.variants,
    required this.cartQuantities,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalInCart = variants.fold<int>(0, (s, v) => s + (cartQuantities[v.id] ?? 0));

    return GestureDetector(
      onTap: () => _showSizePicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: totalInCart > 0
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: totalInCart > 0 ? AppColors.primary : AppColors.cardBorder,
            width: totalInCart > 0 ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🍕', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                baseName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            // Size chips
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: variants.map((v) {
                final sizeLabel = _extractSize(v.name);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    sizeLabel,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
            if (totalInCart > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓  $totalInCart in cart',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _extractSize(String name) {
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(name);
    return match?.group(1) ?? name;
  }

  void _showSizePicker(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍕', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baseName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Choose a size',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemCount: variants.length,
                itemBuilder: (_, i) {
                  final v = variants[i];
                  final sizeLabel = _extractSize(v.name);
                  final qty = cartQuantities[v.id] ?? 0;
                  return GestureDetector(
                    onTap: () {
                      onVariantSelected(v);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: qty > 0
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: qty > 0 ? AppColors.primary : AppColors.cardBorder,
                          width: qty > 0 ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sizeLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(v.price),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (qty > 0)
                            Text(
                              '$qty in cart',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
