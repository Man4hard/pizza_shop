import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/sale_record.dart';

class ApiService {
  // Change this to your Laravel server URL
  static const String baseUrl = 'http://YOUR_SERVER_IP/api';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static void setBaseUrl(String url) {
    // Use shared_preferences to persist this
  }

  // ─── Categories ──────────────────────────────────────────────────────────────

  static Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Category.fromJson(j)).toList();
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }

  static Future<Category> createCategory(String name, {String? icon}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
      body: jsonEncode({'name': name, 'icon': icon}),
    );
    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create category: ${response.body}');
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }

  // ─── Products ────────────────────────────────────────────────────────────────

  static Future<List<Product>> getProducts({int? categoryId}) async {
    final uri = Uri.parse('$baseUrl/products').replace(
      queryParameters: categoryId != null ? {'categoryId': categoryId.toString()} : null,
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Product.fromJson(j)).toList();
    }
    throw Exception('Failed to load products: ${response.statusCode}');
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create product: ${response.body}');
  }

  static Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update product: ${response.body}');
  }

  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }

  // ─── Orders ──────────────────────────────────────────────────────────────────

  static Future<List<Order>> getOrders({String? date, String? status}) async {
    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Order.fromJson(j)).toList();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  static Future<Order> getOrder(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$id'), headers: _headers);
    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load order: ${response.statusCode}');
  }

  static Future<Order> createOrder({
    List<Map<String, dynamic>> items = const [],
    String? customerName,
    String? tableNumber,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'items': items,
        if (customerName != null) 'customerName': customerName,
        if (tableNumber != null) 'tableNumber': tableNumber,
        if (notes != null) 'notes': notes,
      }),
    );
    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create order: ${response.body}');
  }

  static Future<Order> completeOrder(int id, String paymentMethod, {double discount = 0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$id/complete'),
      headers: _headers,
      body: jsonEncode({'paymentMethod': paymentMethod, 'discount': discount}),
    );
    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to complete order: ${response.body}');
  }

  static Future<void> cancelOrder(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/orders/$id/cancel'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel order: ${response.statusCode}');
    }
  }

  // ─── Sales ───────────────────────────────────────────────────────────────────

  static Future<List<SaleRecord>> getSales({String? startDate, String? endDate}) async {
    final uri = Uri.parse('$baseUrl/sales').replace(queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => SaleRecord.fromJson(j)).toList();
    }
    throw Exception('Failed to load sales: ${response.statusCode}');
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  static Future<DashboardSummary> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/summary'), headers: _headers);
    if (response.statusCode == 200) {
      return DashboardSummary.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load summary: ${response.statusCode}');
  }

  static Future<List<TopProduct>> getTopProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/top-products'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => TopProduct.fromJson(j)).toList();
    }
    throw Exception('Failed to load top products: ${response.statusCode}');
  }

  static Future<List<Order>> getRecentOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/recent-orders'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Order.fromJson(j)).toList();
    }
    throw Exception('Failed to load recent orders: ${response.statusCode}');
  }

  static Future<List<HourlySales>> getHourlySales() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/hourly-sales'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => HourlySales.fromJson(j)).toList();
    }
    throw Exception('Failed to load hourly sales: ${response.statusCode}');
  }
}
