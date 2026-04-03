class SaleRecord {
  final int id;
  final int orderId;
  final String orderNumber;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final String? tableNumber;
  final int itemCount;
  final DateTime soldAt;

  SaleRecord({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.total,
    required this.paymentMethod,
    this.customerName,
    this.tableNumber,
    required this.itemCount,
    required this.soldAt,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        id: json['id'],
        orderId: json['orderId'],
        orderNumber: json['orderNumber'],
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['paymentMethod'],
        customerName: json['customerName'],
        tableNumber: json['tableNumber'],
        itemCount: json['itemCount'],
        soldAt: DateTime.parse(json['soldAt']),
      );
}

class DashboardSummary {
  final double totalSalesToday;
  final int totalOrdersToday;
  final double averageOrderValue;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;

  DashboardSummary({
    required this.totalSalesToday,
    required this.totalOrdersToday,
    required this.averageOrderValue,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalSalesToday: (json['totalSalesToday'] as num).toDouble(),
        totalOrdersToday: json['totalOrdersToday'],
        averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
        pendingOrders: json['pendingOrders'],
        completedOrders: json['completedOrders'],
        cancelledOrders: json['cancelledOrders'],
      );
}

class TopProduct {
  final int productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        productId: json['productId'],
        productName: json['productName'],
        quantitySold: json['quantitySold'],
        revenue: (json['revenue'] as num).toDouble(),
      );
}

class HourlySales {
  final int hour;
  final double sales;
  final int orders;

  HourlySales({
    required this.hour,
    required this.sales,
    required this.orders,
  });

  factory HourlySales.fromJson(Map<String, dynamic> json) => HourlySales(
        hour: json['hour'],
        sales: (json['sales'] as num).toDouble(),
        orders: json['orders'],
      );
}
