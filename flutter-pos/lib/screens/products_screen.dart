import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _filterCategoryId;
  bool _loading = true;
  String _search = '';
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

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
        ApiService.getCategories(),
        ApiService.getProducts(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load: $e');
    }
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final matchCat = _filterCategoryId == null || p.categoryId == _filterCategoryId;
      final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
    );
  }

  // ── Toggle availability ───────────────────────────────────────────
  Future<void> _toggleAvailability(Product p) async {
    try {
      await ApiService.updateProduct(p.id, {
        'name': p.name,
        'price': p.price,
        'categoryId': p.categoryId,
        'description': p.description,
        'available': !p.available,
      });
      await _loadData();
      _showSuccess('${p.name} ${!p.available ? "enabled" : "disabled"}');
    } catch (e) {
      _showError('Update failed: $e');
    }
  }

  // ── Delete product ────────────────────────────────────────────────
  Future<void> _deleteProduct(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${p.name}"?\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteProduct(p.id);
      await _loadData();
      _showSuccess('${p.name} deleted');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  // ── Add / Edit product dialog ─────────────────────────────────────
  Future<void> _showProductDialog({Product? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    int? selectedCategoryId = existing?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : null);
    bool available = existing?.available ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          existing == null ? Icons.add_circle_rounded : Icons.edit_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          existing == null ? 'Add New Product' : 'Edit Product',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'e.g. Chicken Tikka Pizza (Large)',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: priceCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs.) *',
                        prefixText: 'Rs. ',
                        hintText: '450',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price is required';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        if (double.parse(v) < 0) return 'Price must be positive';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Category *'),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                      )).toList(),
                      onChanged: (v) => setS(() => selectedCategoryId = v),
                      validator: (v) => v == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: descCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available toggle
                    Row(
                      children: [
                        const Text('Show on Menu', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const Spacer(),
                        Switch(
                          value: available,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setS(() => available = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(ctx);
                              try {
                                final data = {
                                  'name': nameCtrl.text.trim(),
                                  'price': double.parse(priceCtrl.text.trim()),
                                  'categoryId': selectedCategoryId,
                                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                  'available': available,
                                };
                                if (existing == null) {
                                  await ApiService.createProduct(data);
                                  _showSuccess('Product added!');
                                } else {
                                  await ApiService.updateProduct(existing.id, data);
                                  _showSuccess('Product updated!');
                                }
                                await _loadData();
                              } catch (e) {
                                _showError('Save failed: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(existing == null ? 'Add Product' : 'Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildFilters(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
    color: AppColors.surface,
    child: Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Manage your menu items', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
        const Spacer(),
        // Stats
        _statChip(Icons.check_circle_outline_rounded, '${_products.where((p) => p.available).length} active', Colors.green),
        const SizedBox(width: 10),
        _statChip(Icons.hide_source_rounded, '${_products.where((p) => !p.available).length} hidden', AppColors.textMuted),
      ],
    ),
  );

  Widget _statChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildFilters() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Row(
      children: [
        // Search
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                      onPressed: () { _searchController.clear(); setState(() => _search = ''); },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Category filter
        DropdownButton<int?>(
          value: _filterCategoryId,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          underline: const SizedBox.shrink(),
          hint: const Text('All categories', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories', style: TextStyle(color: AppColors.textPrimary))),
            ..._categories.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
            )),
          ],
          onChanged: (v) => setState(() => _filterCategoryId = v),
        ),
      ],
    ),
  );

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No products found', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildProductTile(items[i]),
      ),
    );
  }

  Widget _buildProductTile(Product p) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: p.available ? AppColors.cardBorder : AppColors.error.withOpacity(0.25),
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.available
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.local_pizza_rounded,
          color: p.available ? AppColors.primary : AppColors.textMuted,
          size: 22,
        ),
      ),
      title: Text(
        p.name,
        style: TextStyle(
          color: p.available ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _currency.format(p.price),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.categoryId.toString(),  // Will show category name after enhancement
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              if (!p.available) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Hidden from menu',
                    style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visibility toggle
          Tooltip(
            message: p.available ? 'Hide from menu' : 'Show on menu',
            child: IconButton(
              onPressed: () => _toggleAvailability(p),
              icon: Icon(
                p.available ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: p.available ? Colors.green : AppColors.textMuted,
              ),
            ),
          ),
          // Edit
          Tooltip(
            message: 'Edit product',
            child: IconButton(
              onPressed: () => _showProductDialog(existing: p),
              icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
            ),
          ),
          // Delete
          Tooltip(
            message: 'Delete product',
            child: IconButton(
              onPressed: () => _deleteProduct(p),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
          ),
        ],
      ),
    ),
  );
}
