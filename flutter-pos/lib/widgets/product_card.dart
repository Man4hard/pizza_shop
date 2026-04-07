import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _categoryEmoji(String categoryName) {
  final n = categoryName.toLowerCase();
  if (n.contains('deal'))                            return '🎁';
  if (n.contains('burger') || n.contains('shawarma')) return '🍔';
  if (n.contains('crispy') || n.contains('grilled')) return '🍗';
  return '🍕';
}

Color _categoryColor(String categoryName) {
  final n = categoryName.toLowerCase();
  if (n.contains('deal'))                            return const Color(0xFF7C3AED);
  if (n.contains('burger') || n.contains('shawarma')) return const Color(0xFFD97706);
  if (n.contains('crispy') || n.contains('grilled')) return const Color(0xFF059669);
  if (n.contains('special'))                         return const Color(0xFFDC2626);
  return AppColors.primary;
}

/// Returns a local asset image path for a product name, or null if no image.
String? _productImage(String name) {
  final n = name.toLowerCase();
  if (n.contains('chicken tikka')) return 'assets/images/chicken_tikka_pizza.jpg';
  if (n.contains('fajita'))        return 'assets/images/chicken_fajita_pizza.jpg';
  if (n.contains('bbq'))           return 'assets/images/bbq_pizza.jpg';
  if (n.contains('tandoori'))      return 'assets/images/tandoori_pizza.jpg';
  if (n.contains('ahmed special') || n.contains('ahmad special')) return 'assets/images/ahmad_special_pizza.jpg';
  if (n.contains('hot') && n.contains('spicy')) return 'assets/images/hot_spicy_pizza.jpg';
  return null;
}

/// Header widget: real photo if available, else colored gradient + emoji.
Widget _buildCardHeader({
  required String name,
  required Color color,
  required String emoji,
  Widget? overlay,
}) {
  final imagePath = _productImage(name);

  if (imagePath != null) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
          ),
        ),
        // Dark gradient overlay so badges stay readable
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        if (overlay != null) overlay,
      ],
    );
  }

  // No image → gradient + emoji
  return Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      Positioned(right: -12, top: -12,
        child: Container(width: 60, height: 60,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),
      Positioned(left: -8, bottom: -8,
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
      Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
      if (overlay != null) overlay,
    ],
  );
}

// ── Single Product Card ───────────────────────────────────────────────────────

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
    final color = _categoryColor(product.categoryName ?? '');
    final emoji = _categoryEmoji(product.categoryName ?? '');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart ? color : AppColors.cardBorder,
            width: inCart ? 2 : 1,
          ),
          boxShadow: inCart
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: real photo or gradient+emoji ──
            Expanded(
              flex: 5,
              child: _buildCardHeader(
                name: product.name,
                color: color,
                emoji: emoji,
                overlay: inCart
                    ? Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '×$quantity',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // ── Info section ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: inCart ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grouped Product Card (multi-size pizzas) ──────────────────────────────────

class GroupedProductCard extends StatelessWidget {
  final String baseName;
  final List<Product> variants;
  final Map<int, int> cartQuantities;
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
    final categoryName = variants.first.categoryName ?? '';
    final color = _categoryColor(categoryName);
    final emoji = _categoryEmoji(categoryName);

    return GestureDetector(
      onTap: () => _showSizePicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: totalInCart > 0 ? color : AppColors.cardBorder,
            width: totalInCart > 0 ? 2 : 1,
          ),
          boxShadow: totalInCart > 0
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: real photo or gradient+emoji ──
            Expanded(
              flex: 5,
              child: _buildCardHeader(
                name: baseName,
                color: color,
                emoji: emoji,
                overlay: totalInCart > 0
                    ? Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '×$totalInCart',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // ── Info section ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      baseName,
                      style: TextStyle(
                        color: totalInCart > 0 ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractSize(String name) {
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(name);
    if (match != null) return match.group(1)!;
    // Return first letter if long label
    return name.length <= 3 ? name : name[0];
  }

  void _showSizePicker(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final categoryName = variants.first.categoryName ?? '';
    final color = _categoryColor(categoryName);
    final emoji = _categoryEmoji(categoryName);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(right: -20, top: -20,
                    child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle))),
                  Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baseName,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Tap a size to add to cart',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  ...variants.map((v) {
                    final sizeLabel = _extractSize(v.name);
                    final qty = cartQuantities[v.id] ?? 0;
                    return GestureDetector(
                      onTap: () {
                        onVariantSelected(v);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: qty > 0 ? color.withOpacity(0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: qty > 0 ? color : AppColors.cardBorder,
                            width: qty > 0 ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(sizeLabel,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(v.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currency.format(v.price),
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
                                if (qty > 0)
                                  Text('$qty in cart',
                                    style: TextStyle(color: color, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
