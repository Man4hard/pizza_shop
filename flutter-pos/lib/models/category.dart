class Category {
  final int id;
  final String name;
  final String? icon;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
      };
}
