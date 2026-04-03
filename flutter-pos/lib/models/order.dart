class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'],
        productId: json['productId'],
        productName: json['productName'],
        quantity: json['quantity'],
        unitPrice: (json['unitPrice'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String? customerName;
  final String? tableNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.tax,
    this.discount = 0,
    required this.total,
    this.paymentMethod,
    this.customerName,
    this.tableNumber,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        orderNumber: json['orderNumber'],
        status: json['status'],
        subtotal: (json['subtotal'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['paymentMethod'],
        customerName: json['customerName'],
        tableNumber: json['tableNumber'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromJson(i))
                .toList() ??
            [],
      );
}

class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;
}
