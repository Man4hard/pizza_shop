import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _customerName;
  String? _tableNumber;
  String? _notes;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get customerName => _customerName;
  String? get tableNumber => _tableNumber;
  String? get notes => _notes;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  double get tax => 0;
  double get total => subtotal;

  void setCustomerInfo({String? name, String? table, String? notes}) {
    _customerName = name;
    _tableNumber = table;
    _notes = notes;
    notifyListeners();
  }

  void addProduct(Product product) {
    final existing = _items.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => CartItem(
        productId: -1,
        productName: '',
        unitPrice: 0,
      ),
    );

    if (existing.productId == product.id) {
      existing.quantity++;
    } else {
      _items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
      ));
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    final existing = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(productId: -1, productName: '', unitPrice: 0),
    );

    if (existing.productId == productId) {
      if (existing.quantity > 1) {
        existing.quantity--;
      } else {
        _items.removeWhere((item) => item.productId == productId);
      }
    }
    notifyListeners();
  }

  void deleteProduct(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _customerName = null;
    _tableNumber = null;
    _notes = null;
    notifyListeners();
  }

  int quantityOf(int productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId).quantity;
    } catch (_) {
      return 0;
    }
  }

  List<Map<String, dynamic>> toOrderItems() {
    return _items
        .map((item) => {
              'productId': item.productId,
              'quantity': item.quantity,
            })
        .toList();
  }
}
