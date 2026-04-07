import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/category.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Category> _categories = [];
  List<Product> _products = [];
  Map<int, int> _categoryProductCounts = {};
  int? _filterCategoryId;
  bool _loading = true;
  String _search = '';
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
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
      final cats = results[0] as List<Category>;
      final prods = results[1] as List<Product>;

      final counts = <int, int>{};
      for (final c in cats) {
        counts[c.id] = prods.where((p) => p.categoryId == c.id).length;
      }

      setState(() {
        _categories = cats;
        _products = prods;
        _categoryProductCounts = counts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
      await DatabaseService.updateProduct(p.id, {
        'name': p.name,
        'price': p.price,
        'categoryId': p.categoryId,
        'description': p.description,
        'available': !p.available,
      });
      await _loadData();
      _showSuccess('${p.name} ${p.available ? "disabled" : "enabled"}');
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
      await DatabaseService.deleteProduct(p.id);
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
    String? pickedImagePath = existing?.imageUrl;
    final formKey = GlobalKey<FormState>();

    Future<void> pickImage(StateSetter setS) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final saved = await File(picked.path).copy('${appDir.path}/$fileName');
      setS(() => pickedImagePath = saved.path);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
            child: SingleChildScrollView(
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
                      decoration: InputDecoration(
                        labelText: 'Name *',
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
                      decoration: InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                      )).toList(),
                      onChanged: (v) => setS(() => selectedCategoryId = v),
                      validator: (v) => v == null ? 'Select category' : null,
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

                    // Product image picker
                    GestureDetector(
                      onTap: () => pickImage(setS),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pickedImagePath != null ? AppColors.primary : AppColors.cardBorder,
                            width: pickedImagePath != null ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pickedImagePath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  pickedImagePath!.startsWith('/')
                                      ? Image.file(File(pickedImagePath!), fit: BoxFit.cover)
                                      : Image.asset(pickedImagePath!, fit: BoxFit.cover),
                                  Positioned(
                                    bottom: 8, right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      color: AppColors.textMuted, size: 36),
                                  const SizedBox(height: 8),
                                  const Text('Tap to add product image',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available toggle
                    Row(
                      children: [
                        Text('Available', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                                  'imageUrl': pickedImagePath,
                                };
                                if (existing == null) {
                                  await DatabaseService.createProduct(data);
                                  _showSuccess('Product added!');
                                } else {
                                  await DatabaseService.updateProduct(existing.id, data);
                                  _showSuccess('Product updated!');
                                }
                                await _loadData();
                              } catch (e) {
                                _showError('${'Update failed'}: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              existing == null ? 'Add Product' : 'Save Changes',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  // ── Add / Edit category dialog ────────────────────────────────────
  static const _emojiOptions = [
    '🍕', '🍔', '🥩', '🌯', '🍟', '🥪', '🍗',
    '🥗', '🥘', '🍜', '🌮', '🫔', '🧆', '🌶️',
    '🎂', '🍰', '🧁', '☕', '🥤', '🍺', '🧃',
    '🔥', '⭐', '🎉', '🍽️', '🛒', '🥡', '🍱',
  ];

  Future<void> _showCategoryDialog({Category? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.icon;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          existing == null ? Icons.add_circle_rounded : Icons.edit_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          existing == null ? 'Add Category' : 'Edit Category',
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
                    const SizedBox(height: 20),

                    // Preview circle
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: selectedEmoji != null
                              ? Text(selectedEmoji!, style: const TextStyle(fontSize: 36))
                              : const Icon(Icons.category_rounded, color: AppColors.primary, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Sandwiches, Drinks...',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Emoji picker
                    Text(
                      'Choose an Icon (optional)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _emojiOptions.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            final isSelected = selectedEmoji == null;
                            return GestureDetector(
                              onTap: () => setS(() => selectedEmoji = null),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: const Icon(Icons.block_rounded, size: 20, color: AppColors.textMuted),
                              ),
                            );
                          }
                          final emoji = _emojiOptions[i - 1];
                          final isSelected = selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setS(() => selectedEmoji = emoji),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                          );
                        },
                      ),
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
                                if (existing == null) {
                                  await DatabaseService.createCategory(
                                    nameCtrl.text.trim(),
                                    icon: selectedEmoji,
                                  );
                                  _showSuccess('Category added!');
                                } else {
                                  await DatabaseService.updateCategory(
                                    existing.id,
                                    nameCtrl.text.trim(),
                                    icon: selectedEmoji,
                                  );
                                  _showSuccess('Category updated!');
                                }
                                await _loadData();
                              } catch (e) {
                                _showError('Save failed: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              existing == null ? 'Add Category' : 'Save',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  // ── Delete category ───────────────────────────────────────────────
  Future<void> _deleteCategory(Category cat) async {
    final count = _categoryProductCounts[cat.id] ?? 0;
    if (count > 0) {
      _showError('Cannot delete "${cat.name}" — it has $count product${count == 1 ? "" : "s"}. Move or delete them first.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${cat.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      await DatabaseService.deleteCategory(cat.id);
      await _loadData();
      _showSuccess('"${cat.name}" deleted');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isProductsTab = _tabs.index == 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(isProductsTab),
          // Tab bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Categories'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildProductsTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: isProductsTab
          ? FloatingActionButton.extended(
              onPressed: () => _showProductDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _buildTopBar(bool isProductsTab) {
    return SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProductsTab ? 'Products' : 'Categories',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isProductsTab ? 'Manage Products' : 'Categories',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isProductsTab) ...[
            _statChip(Icons.check_circle_outline_rounded, '${$a} active' => p.available).length), Colors.green),
            const SizedBox(width: 8),
            _statChip(Icons.hide_source_rounded, '${$a} hidden' => !p.available).length), AppColors.textMuted),
          ] else ...[
            _statChip(Icons.category_rounded, '${$a} cats', AppColors.primary),
          ],
        ],
      ),
    ),
  );
  }

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

  // ── Products tab ──────────────────────────────────────────────────

  Widget _buildProductsTab() => Column(
    children: [
      _buildFilters(),
      Expanded(child: _buildProductList()),
    ],
  );

  Widget _buildFilters() {
    return Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Row(
      children: [
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
        DropdownButton<int?>(
          value: _filterCategoryId,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          underline: const SizedBox.shrink(),
          hint: Text('All', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          items: [
            DropdownMenuItem(value: null, child: Text('All', style: const TextStyle(color: AppColors.textPrimary))),
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
  }

  Widget _buildProductList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No items found', style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          if (Breakpoints.isWide(w)) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                mainAxisExtent: 76,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _buildProductTile(items[i]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildProductTile(items[i]),
          );
        },
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Container(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.name,
                style: TextStyle(
                  color: p.available ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _currency.format(p.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.categoryName ?? 'Category ${p.categoryId}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                  if (!p.available)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hidden',
                        style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(
              icon: p.available ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: p.available ? Colors.green : AppColors.textMuted,
              tooltip: p.available ? 'Hide from menu' : 'Show on menu',
              onTap: () => _toggleAvailability(p),
            ),
            _actionBtn(
              icon: Icons.edit_rounded,
              color: AppColors.textSecondary,
              tooltip: 'Edit product',
              onTap: () => _showProductDialog(existing: p),
            ),
            _actionBtn(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              tooltip: 'Delete',
              onTap: () => _deleteProduct(p),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      );

  // ── Categories tab ────────────────────────────────────────────────

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No categories yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap "+ Add Category" to create one', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Category', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          final cols = Breakpoints.isWide(w) ? 2 : 1;
          if (cols > 1) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: cols == 3 ? 1.7 : 1.9,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category cat) {
    final productCount = _categoryProductCounts[cat.id] ?? 0;
    final hasIcon = cat.icon != null && cat.icon!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: hasIcon
                      ? Text(cat.icon!, style: const TextStyle(fontSize: 26))
                      : const Icon(Icons.category_rounded, color: AppColors.primary, size: 26),
                ),
              ),
              const Spacer(),
              _actionBtn(
                icon: Icons.edit_rounded,
                color: AppColors.textSecondary,
                tooltip: 'Edit category',
                onTap: () => _showCategoryDialog(existing: cat),
              ),
              _actionBtn(
                icon: Icons.delete_outline_rounded,
                color: productCount > 0 ? AppColors.textMuted : AppColors.error,
                tooltip: productCount > 0 ? 'Has ${$a == 1 ? "1 product" : "${$a} products"} — cannot delete' : 'Delete category',
                onTap: () => _deleteCategory(cat),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cat.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${$a == 1 ? "1 product" : "${$a} products"}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
