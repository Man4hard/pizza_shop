class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int categoryId;
  final String? categoryName;
  final String? imageUrl;
  final bool available;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    this.categoryName,
    this.imageUrl,
    required this.available,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        imageUrl: json['imageUrl'],
        available: json['available'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'available': available,
        'createdAt': createdAt.toIso8601String(),
      };
}
