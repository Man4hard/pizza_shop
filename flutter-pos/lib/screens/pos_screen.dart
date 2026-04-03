import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/bill_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  bool _loading = true;
  String _search = '';
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  // Size suffixes used in the seeder
  static const _sizeSuffixes = ['(Small)', '(Medium)', '(Large)', '(XL)', '(S)', '(M)', '(L)'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DatabaseService.getCategories(),
        DatabaseService.getProducts(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadProducts(int? categoryId) async {
    setState(() => _selectedCategoryId = categoryId);
    try {
      final products = await DatabaseService.getProducts(categoryId: categoryId);
      setState(() => _products = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Product grouping helpers ────────────────────────────────────────

  /// Strip size suffix from a product name to get the base name.
  String _baseName(String name) {
    for (final suffix in _sizeSuffixes) {
      if (name.endsWith(' $suffix')) {
        return name.substring(0, name.length - suffix.length - 1).trim();
      }
    }
    return name;
  }

  bool _hasSizeSuffix(String name) => _sizeSuffixes.any((s) => name.endsWith(' $s'));

  /// Groups products that share a base name into lists.
  /// Returns an ordered list of [_ProductGroup] objects.
  List<_ProductGroup> _groupProducts(List<Product> products) {
    final Map<String, List<Product>> byBase = {};
    final List<String> order = [];

    for (final p in products) {
      if (!p.available) continue;
      final base = _baseName(p.name);
      if (!byBase.containsKey(base)) {
        byBase[base] = [];
        order.add(base);
      }
      byBase[base]!.add(p);
    }

    return order.map((base) {
      final variants = byBase[base]!;
      final isGrouped = variants.length > 1 || _hasSizeSuffix(variants.first.name);
      return _ProductGroup(baseName: base, variants: variants, isGrouped: isGrouped);
    }).toList();
  }

  List<_ProductGroup> get _filteredGroups {
    final available = _products.where((p) => p.available).toList();
    final filtered = _search.isEmpty
        ? available
        : available.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();
    return _groupProducts(filtered);
  }

  // ── Order placement ────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    try {
      final info = await _showCustomerInfoDialog();
      if (info == null) return;

      final payment = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PaymentDialog(
          subtotal: cart.subtotal,
          tax: cart.tax,
          total: cart.total,
        ),
      );
      if (payment == null) return;

      final order = await DatabaseService.createOrder(
        items: cart.toOrderItems(),
        customerName: info['customerName'],
        tableNumber: info['tableNumber'],
        notes: info['notes'],
      );

      final completed = await DatabaseService.completeOrder(
        order.id,
        payment['method'],
        discount: payment['discount'] ?? 0,
      );

      cart.clear();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => BillDialog(order: completed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<Map<String, String?>?> _showCustomerInfoDialog() async {
    final nameCtrl = TextEditingController();
    final tableCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Customer Info', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Customer Name (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tableCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Table Number (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'customerName': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              'tableNumber': tableCtrl.text.trim().isEmpty ? null : tableCtrl.text.trim(),
              'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            }),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Row(
              children: [
                Expanded(flex: 3, child: _buildMenuPanel()),
                Container(width: 1, color: AppColors.divider),
                SizedBox(width: 340, child: _buildCartPanel()),
              ],
            ),
    );
  }

  Widget _buildMenuPanel() => Column(
    children: [
      _buildSearchBar(),
      _buildCategoryTabs(),
      Expanded(child: _buildProductGrid()),
    ],
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: TextField(
      controller: _searchController,
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText: 'Search pizza, burger, shawarma, deal...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
              )
            : null,
      ),
    ),
  );

  Widget _buildCategoryTabs() => SizedBox(
    height: 56,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _categories.length + 1,
      itemBuilder: (_, i) {
        final isAll = i == 0;
        final selected = isAll ? _selectedCategoryId == null : _categories[i - 1].id == _selectedCategoryId;
        final label = isAll ? 'All' : _categories[i - 1].name;
        return GestureDetector(
          onTap: () => _loadProducts(isAll ? null : _categories[i - 1].id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.cardBorder,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildProductGrid() {
    final groups = _filteredGroups;
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pizza_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No items found', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return Consumer<CartProvider>(
      builder: (_, cart, __) => GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final group = groups[i];

          if (group.isGrouped) {
            // Multi-size pizza: tap → size picker
            final qtyMap = {for (final v in group.variants) v.id: cart.quantityOf(v.id)};
            return GroupedProductCard(
              baseName: group.baseName,
              variants: group.variants,
              cartQuantities: qtyMap,
              onVariantSelected: (product) => cart.addProduct(product),
            );
          } else {
            // Single product (burger, deal, grilled): tap once → add
            final product = group.variants.first;
            return ProductCard(
              product: product,
              quantity: cart.quantityOf(product.id),
              onTap: () => cart.addProduct(product),
            );
          }
        },
      ),
    );
  }

  // ── Cart panel ─────────────────────────────────────────────────────

  Widget _buildCartPanel() => Consumer<CartProvider>(
    builder: (_, cart, __) => Column(
      children: [
        _buildCartHeader(cart),
        Expanded(child: _buildCartItems(cart)),
        _buildCartSummary(cart),
        _buildCartFooter(cart),
      ],
    ),
  );

  Widget _buildCartHeader(CartProvider cart) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        const Text(
          'Current Order',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (cart.items.isNotEmpty)
          GestureDetector(
            onTap: cart.clear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildCartItems(CartProvider cart) {
    if (cart.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Cart is empty', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            SizedBox(height: 4),
            Text('Tap items to add them', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return CartItemTile(
          item: item,
          onAdd: () => cart.addProduct(
            Product(
              id: item.productId,
              name: item.productName,
              price: item.unitPrice,
              categoryId: 0,
              available: true,
              createdAt: DateTime.now(),
            ),
          ),
          onRemove: () => cart.removeProduct(item.productId),
          onDelete: () => cart.deleteProduct(item.productId),
        );
      },
    );
  }

  Widget _buildCartSummary(CartProvider cart) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Column(
      children: [
        _summaryRow('Subtotal', cart.subtotal),
        const SizedBox(height: 8),
        _summaryRow('Tax (10%)', cart.tax),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              _currency.format(cart.total),
              style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summaryRow(String label, double amount) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(_currency.format(amount), style: const TextStyle(color: AppColors.textSecondary)),
    ],
  );

  Widget _buildCartFooter(CartProvider cart) => Container(
    padding: const EdgeInsets.all(20),
    color: AppColors.surface,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: cart.items.isNotEmpty ? _placeOrder : null,
        icon: const Icon(Icons.point_of_sale_rounded),
        label: Text(
          cart.items.isEmpty
              ? 'Add items to order'
              : 'Place Order • ${_currency.format(cart.total)}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    ),
  );
}

// ── Internal data class ──────────────────────────────────────────────
class _ProductGroup {
  final String baseName;
  final List<Product> variants;
  final bool isGrouped;
  const _ProductGroup({required this.baseName, required this.variants, required this.isGrouped});
}
