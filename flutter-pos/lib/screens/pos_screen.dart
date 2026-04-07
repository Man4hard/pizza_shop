import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import '../services/cart_provider.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_tile.dart';
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
        final s = context.read<LocaleProvider>().strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.errorLoadingData}: $e'), backgroundColor: AppColors.error),
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
        final s = context.read<LocaleProvider>().strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.errorStr}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _baseName(String name) {
    for (final suffix in _sizeSuffixes) {
      if (name.endsWith(' $suffix')) {
        return name.substring(0, name.length - suffix.length - 1).trim();
      }
    }
    return name;
  }

  bool _hasSizeSuffix(String name) => _sizeSuffixes.any((s) => name.endsWith(' $s'));

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

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;
    try {
      final info = await _showCustomerInfoDialog();
      if (info == null) return;
      final order = await DatabaseService.createOrder(
        items: cart.toOrderItems(),
        customerName: info['customerName'],
        tableNumber: info['tableNumber'],
        notes: info['notes'],
      );
      final completed = await DatabaseService.completeOrder(order.id, 'cash', discount: 0);
      cart.clear();
      if (mounted) {
        await showDialog(context: context, builder: (_) => BillDialog(order: completed));
      }
    } catch (e) {
      if (mounted) {
        final s = context.read<LocaleProvider>().strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.orderFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<Map<String, String?>?> _showCustomerInfoDialog() async {
    final s = context.read<LocaleProvider>().strings;
    final nameCtrl = TextEditingController();
    final tableCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    return showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.customerInfo, style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: s.customerNameField),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tableCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: s.tableNumberField),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: s.notesField),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'customerName': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              'tableNumber': tableCtrl.text.trim().isEmpty ? null : tableCtrl.text.trim(),
              'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            }),
            child: Text(s.continueBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final isMobile = Breakpoints.isPhone(MediaQuery.of(context).size.width);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isMobile
              ? _buildMobileLayout()
              : Row(
                  children: [
                    Expanded(child: _buildProductsPane()),
                    Container(width: 1, color: AppColors.divider),
                    SizedBox(width: 340, child: _buildCartPanel()),
                  ],
                ),
    );
  }

  Widget _buildMobileLayout() => Consumer<CartProvider>(
    builder: (_, cart, __) => Column(
      children: [
        Expanded(child: _buildProductsPane()),
        _buildMobileCartBar(cart),
      ],
    ),
  );

  Widget _buildMobileCartBar(CartProvider cart) {
    final s = context.watch<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: cart.items.isNotEmpty ? () => _showCartSheet() : null,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                cart.items.isEmpty
                    ? s.cartEmpty
                    : '${cart.items.length} ${s.itemsLabel} • ${_currency.format(cart.total)}',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: cart.items.isNotEmpty ? _placeOrder : null,
              child: Text(s.placeOrder),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Consumer<CartProvider>(
          builder: (_, cart, __) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildCartHeader(cart),
              Expanded(child: _buildCartItems(cart)),
              _buildCartSummary(cart),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: cart.items.isNotEmpty
                        ? () {
                            Navigator.pop(context);
                            _placeOrder();
                          }
                        : null,
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: Builder(builder: (ctx) {
                      final s = ctx.watch<LocaleProvider>().strings;
                      return Text(
                        cart.items.isEmpty
                            ? s.addItemsToOrder
                            : '${s.placeOrder} • ${_currency.format(cart.total)}',
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsPane() {
    final s = context.watch<LocaleProvider>().strings;
    return Column(
      children: [
        _buildSearchBar(s),
        _buildCategoryChips(s),
        Expanded(child: _buildProductGrid(s)),
      ],
    );
  }

  Widget _buildSearchBar(s) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: TextField(
      controller: _searchController,
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText: s.searchHint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
              )
            : null,
      ),
    ),
  );

  Widget _buildCategoryChips(s) => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final selected = i == 0 ? _selectedCategoryId == null : _categories[i - 1].id == _selectedCategoryId;
        final label = i == 0 ? s.allCategories : (_categories[i - 1].icon != null ? '${_categories[i - 1].icon} ${_categories[i - 1].name}' : _categories[i - 1].name);
        return GestureDetector(
          onTap: () => _loadProducts(i == 0 ? null : _categories[i - 1].id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildProductGrid(s) {
    final groups = _filteredGroups;
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_pizza_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(s.noItemsFound, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return Consumer<CartProvider>(
      builder: (_, cart, __) => LayoutBuilder(
        builder: (_, constraints) {
          final cols = Breakpoints.isWide(constraints.maxWidth) ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: cols == 3 ? 0.82 : 0.85,
            ),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final group = groups[i];
              if (group.isGrouped) {
                final qtyMap = {for (final v in group.variants) v.id: cart.quantityOf(v.id)};
                return GroupedProductCard(
  
                  baseName: group.baseName,
  
                  variants: group.variants,
  
                  cartQuantities: qtyMap,
  
                  onVariantSelected: (p) => cart.addProduct(p),
  
                );
              } else {
                final p = group.variants.first;
                return ProductCard(
  
                  product: p,
  
                  quantity: cart.quantityOf(p.id),
  
                  onTap: () => cart.addProduct(p),
  
                );
              }
            },
          );
        },
      ),
    );
  }

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

  Widget _buildCartHeader(CartProvider cart) {
    final s = context.watch<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text(
            s.currentOrder,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
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
                child: Text(
                  s.clearCart,
                  style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    final s = context.watch<LocaleProvider>().strings;
    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(s.cartEmpty, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 4),
            Text(s.tapItemsToAdd, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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

  Widget _buildCartSummary(CartProvider cart) {
    final s = context.watch<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.total, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(_currency.format(cart.total),
                  style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter(CartProvider cart) {
    final s = context.watch<LocaleProvider>().strings;
    return Container(
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
                ? s.addItemsToOrder
                : '${s.placeOrder} • ${_currency.format(cart.total)}',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _ProductGroup {
  final String baseName;
  final List<Product> variants;
  final bool isGrouped;
  const _ProductGroup({required this.baseName, required this.variants, required this.isGrouped});
}
