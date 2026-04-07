import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/sale_record.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ahmed_pos.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        image_url TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        subtotal REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        payment_method TEXT,
        customer_name TEXT,
        table_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        order_number TEXT NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        customer_name TEXT,
        table_number TEXT,
        item_count INTEGER NOT NULL,
        sold_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    await _seedData(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
    }
  }

  static Future<void> _seedData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert categories first (need IDs for products)
    final regularId = await db.insert('categories', {'name': 'Regular Pizzas',     'icon': '🍕', 'created_at': now});
    final specialId = await db.insert('categories', {'name': 'Special Pizzas',     'icon': '⭐', 'created_at': now});
    final dealsId   = await db.insert('categories', {'name': 'Special Deals',      'icon': '🎁', 'created_at': now});
    final burgersId = await db.insert('categories', {'name': 'Burgers & Shawarma', 'icon': '🍔', 'created_at': now});
    final grilledId = await db.insert('categories', {'name': 'Crispy & Grilled',   'icon': '🍗', 'created_at': now});

    // Batch ALL product inserts in one transaction — 51 inserts become 1 DB round-trip
    final batch = db.batch();

    // ── Regular Pizzas ──────────────────────────────────────────────────────
    final regularFlavors = {
      'Chicken Tikka Pizza':  [450.0, 900.0, 1250.0, 1750.0],
      'Chicken Fajita Pizza': [450.0, 900.0, 1250.0, 1750.0],
      'BBQ Pizza':            [450.0, 900.0, 1250.0, 1750.0],
      'Tandoori Pizza':       [450.0, 900.0, 1250.0, 1750.0],
      'Hot & Spicy Pizza':    [450.0, 900.0, 1250.0, 1750.0],
    };
    final sizes = ['Small', 'Medium', 'Large', 'XL'];
    for (final entry in regularFlavors.entries) {
      for (int i = 0; i < sizes.length; i++) {
        batch.insert('products', {
          'category_id': regularId,
          'name': '${entry.key} (${sizes[i]})',
          'description': '${entry.key} — ${sizes[i]} size',
          'price': entry.value[i],
          'available': 1,
          'created_at': now,
        });
      }
    }

    // ── Special Pizzas ──────────────────────────────────────────────────────
    final specialFlavors = {
      'Ahmed Special Pizza':       [550.0, 1000.0, 1350.0, 1950.0],
      'Chicken Malai Boti Pizza':  [550.0, 1050.0, 1350.0, 1950.0],
      'Kababish Pizza':            [550.0, 1050.0, 1350.0, 2150.0],
      'Crown Crust Pizza':         [650.0, 1100.0, 1550.0, 2350.0],
    };
    for (final entry in specialFlavors.entries) {
      for (int i = 0; i < sizes.length; i++) {
        batch.insert('products', {
          'category_id': specialId,
          'name': '${entry.key} (${sizes[i]})',
          'description': '${entry.key} — ${sizes[i]} size (Special Flavor)',
          'price': entry.value[i],
          'available': 1,
          'created_at': now,
        });
      }
    }

    // ── Special Deals ───────────────────────────────────────────────────────
    final deals = [
      {'name': 'Deal 1', 'price': 1000.0, 'description': '2 Small Pizzas + 1 Liter Drink'},
      {'name': 'Deal 2', 'price': 1950.0, 'description': '2 Medium Pizzas + 1.5 Liter Drink'},
      {'name': 'Deal 3', 'price': 2650.0, 'description': '2 Large Pizzas + 1.5 Liter Drink'},
      {'name': 'Deal 4', 'price': 500.0,  'description': '1 Shawarma + 1 Chicken Burger + Half Liter Drink'},
      {'name': 'Deal 5', 'price': 850.0,  'description': '1 Small Pizza + 1 Zinger Burger + Half Liter Drink'},
      {'name': 'Deal 6', 'price': 1900.0, 'description': '1 Medium Pizza + 1 Zinger Burger + Large Fries + Half Liter Drink'},
      {'name': 'Deal 7', 'price': 2650.0, 'description': '1 Small Pizza + 1 Medium Pizza + 1 Large Pizza'},
      {'name': 'Deal 8', 'price': 2800.0, 'description': '4 Zinger Burgers + 24 Crispy Wings + 2 Regular Fries + 1.5 Liter Drink'},
      {'name': 'Deal 9', 'price': 2450.0, 'description': '3 Small Pizzas + 12 Nuggets + 1 Family Fries + 1.5 Liter Drink'},
    ];
    for (final d in deals) {
      batch.insert('products', {
        'category_id': dealsId,
        'name': d['name'],
        'description': d['description'],
        'price': d['price'],
        'available': 1,
        'created_at': now,
      });
    }

    // ── Burgers & Shawarma ──────────────────────────────────────────────────
    final burgers = [
      {'name': 'Zinger Shawarma',   'price': 330.0, 'description': 'Crispy zinger in a shawarma wrap'},
      {'name': 'Zinger Burger',     'price': 330.0, 'description': 'Crispy zinger chicken burger'},
      {'name': 'Chicken Shawarma',  'price': 180.0, 'description': 'Classic chicken shawarma wrap'},
      {'name': 'Anda Shami Burger', 'price': 150.0, 'description': 'Egg & shami patty burger'},
    ];
    for (final b in burgers) {
      batch.insert('products', {
        'category_id': burgersId,
        'name': b['name'],
        'description': b['description'],
        'price': b['price'],
        'available': 1,
        'created_at': now,
      });
    }

    // ── Crispy & Grilled ────────────────────────────────────────────────────
    final grilled = [
      {'name': 'Special Angara Chicken', 'price': 1500.0, 'description': 'Special Angara chicken — price per kg'},
      {'name': 'Grill Fish',             'price': 1350.0, 'description': 'Special grill fish — price per kg'},
    ];
    for (final g in grilled) {
      batch.insert('products', {
        'category_id': grilledId,
        'name': g['name'],
        'description': g['description'],
        'price': g['price'],
        'available': 1,
        'created_at': now,
      });
    }

    // Commit everything in one shot
    await batch.commit(noResult: true);
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  static Future<List<Category>> getCategories() async {
    final database = await db;
    final rows = await database.query('categories', orderBy: 'id ASC');
    return rows.map((r) => Category(
      id: r['id'] as int,
      name: r['name'] as String,
      icon: r['icon'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  static Future<Category> createCategory(String name, {String? icon}) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();
    final id = await database.insert('categories', {
      'name': name,
      'icon': icon,
      'created_at': now,
    });
    return Category(id: id, name: name, icon: icon, createdAt: DateTime.now());
  }

  static Future<void> updateCategory(int id, String name, {String? icon}) async {
    final database = await db;
    await database.update(
      'categories',
      {'name': name, 'icon': icon},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getProductCountForCategory(int categoryId) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  static Future<void> deleteCategory(int id) async {
    final database = await db;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Products ─────────────────────────────────────────────────────────────

  static Future<List<Product>> getProducts({int? categoryId}) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ${categoryId != null ? 'WHERE p.category_id = ?' : ''}
      ORDER BY p.category_id ASC, p.id ASC
    ''', categoryId != null ? [categoryId] : []);

    return rows.map((r) => Product(
      id: r['id'] as int,
      name: r['name'] as String,
      description: r['description'] as String?,
      price: (r['price'] as num).toDouble(),
      categoryId: r['category_id'] as int,
      categoryName: r['category_name'] as String?,
      available: (r['available'] as int) == 1,
      createdAt: DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();
    final id = await database.insert('products', {
      'category_id': data['categoryId'],
      'name': data['name'],
      'description': data['description'],
      'price': data['price'],
      'available': (data['available'] ?? true) ? 1 : 0,
      'image_url': data['imageUrl'],
      'created_at': now,
    });
    final rows = await database.rawQuery(
      'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?',
      [id],
    );
    final r = rows.first;
    return Product(
      id: id,
      name: r['name'] as String,
      description: r['description'] as String?,
      price: (r['price'] as num).toDouble(),
      categoryId: r['category_id'] as int,
      categoryName: r['category_name'] as String?,
      available: (r['available'] as int) == 1,
      imageUrl: r['image_url'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }

  static Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final database = await db;
    final update = <String, dynamic>{};
    if (data.containsKey('name'))        update['name']        = data['name'];
    if (data.containsKey('description')) update['description'] = data['description'];
    if (data.containsKey('price'))       update['price']       = data['price'];
    if (data.containsKey('categoryId'))  update['category_id'] = data['categoryId'];
    if (data.containsKey('available'))   update['available']   = data['available'] ? 1 : 0;
    if (data.containsKey('imageUrl'))    update['image_url']   = data['imageUrl'];

    await database.update('products', update, where: 'id = ?', whereArgs: [id]);
    final rows = await database.rawQuery(
      'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?',
      [id],
    );
    final r = rows.first;
    return Product(
      id: id,
      name: r['name'] as String,
      description: r['description'] as String?,
      price: (r['price'] as num).toDouble(),
      categoryId: r['category_id'] as int,
      categoryName: r['category_name'] as String?,
      available: (r['available'] as int) == 1,
      imageUrl: r['image_url'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }

  static Future<void> deleteProduct(int id) async {
    final database = await db;
    await database.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  static Future<Order> createOrder({
    List<Map<String, dynamic>> items = const [],
    String? customerName,
    String? tableNumber,
    String? notes,
  }) async {
    final database = await db;
    final now = DateTime.now();

    double subtotal = 0;
    for (final item in items) {
      final rows = await database.query('products', where: 'id = ?', whereArgs: [item['productId']]);
      if (rows.isNotEmpty) {
        final price = (rows.first['price'] as num).toDouble();
        subtotal += price * (item['quantity'] as int);
      }
    }

    final tax = 0.0;
    final total = subtotal;
    final orderNumber = 'ORD-${now.millisecondsSinceEpoch}';

    final orderId = await database.insert('orders', {
      'order_number': orderNumber,
      'status': 'pending',
      'subtotal': subtotal,
      'tax': tax,
      'discount': 0,
      'total': total,
      'customer_name': customerName,
      'table_number': tableNumber,
      'notes': notes,
      'created_at': now.toIso8601String(),
    });

    final List<OrderItem> orderItems = [];
    for (final item in items) {
      final rows = await database.query('products', where: 'id = ?', whereArgs: [item['productId']]);
      if (rows.isNotEmpty) {
        final product = rows.first;
        final price = (product['price'] as num).toDouble();
        final qty = item['quantity'] as int;
        final itemSubtotal = price * qty;

        final itemId = await database.insert('order_items', {
          'order_id': orderId,
          'product_id': item['productId'],
          'product_name': product['name'],
          'quantity': qty,
          'unit_price': price,
          'subtotal': itemSubtotal,
        });

        orderItems.add(OrderItem(
          id: itemId,
          productId: item['productId'],
          productName: product['name'] as String,
          quantity: qty,
          unitPrice: price,
          subtotal: itemSubtotal,
        ));
      }
    }

    return Order(
      id: orderId,
      orderNumber: orderNumber,
      status: 'pending',
      subtotal: subtotal,
      tax: tax,
      discount: 0,
      total: total,
      customerName: customerName,
      tableNumber: tableNumber,
      notes: notes,
      createdAt: now,
      items: orderItems,
    );
  }

  static Future<Order> completeOrder(int id, String paymentMethod, {double discount = 0}) async {
    final database = await db;
    final now = DateTime.now();

    final rows = await database.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Order not found');
    final row = rows.first;

    double subtotal = (row['subtotal'] as num).toDouble();
    double tax = (row['tax'] as num).toDouble();
    double total = subtotal + tax - discount;
    if (total < 0) total = 0;

    await database.update('orders', {
      'status': 'completed',
      'payment_method': paymentMethod,
      'discount': discount,
      'total': total,
      'completed_at': now.toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);

    final itemRows = await database.query('order_items', where: 'order_id = ?', whereArgs: [id]);
    final itemCount = itemRows.fold<int>(0, (sum, r) => sum + (r['quantity'] as int));

    await database.insert('sale_records', {
      'order_id': id,
      'order_number': row['order_number'],
      'total': total,
      'payment_method': paymentMethod,
      'customer_name': row['customer_name'],
      'table_number': row['table_number'],
      'item_count': itemCount,
      'sold_at': now.toIso8601String(),
    });

    return await getOrder(id);
  }

  static Future<void> cancelOrder(int id) async {
    final database = await db;
    await database.update(
      'orders',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Order>> getOrders({String? status, String? date}) async {
    final database = await db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('o.status = ?');
      args.add(status);
    }
    if (date != null) {
      conditions.add("date(o.created_at) = ?");
      args.add(date);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final rows = await database.rawQuery('''
      SELECT o.* FROM orders o $where ORDER BY o.id DESC
    ''', args);

    final orders = <Order>[];
    for (final r in rows) {
      final itemRows = await database.query('order_items', where: 'order_id = ?', whereArgs: [r['id']]);
      final items = itemRows.map((i) => OrderItem(
        id: i['id'] as int,
        productId: i['product_id'] as int,
        productName: i['product_name'] as String,
        quantity: i['quantity'] as int,
        unitPrice: (i['unit_price'] as num).toDouble(),
        subtotal: (i['subtotal'] as num).toDouble(),
      )).toList();

      orders.add(Order(
        id: r['id'] as int,
        orderNumber: r['order_number'] as String,
        status: r['status'] as String,
        subtotal: (r['subtotal'] as num).toDouble(),
        tax: (r['tax'] as num).toDouble(),
        discount: (r['discount'] as num).toDouble(),
        total: (r['total'] as num).toDouble(),
        paymentMethod: r['payment_method'] as String?,
        customerName: r['customer_name'] as String?,
        tableNumber: r['table_number'] as String?,
        notes: r['notes'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        completedAt: r['completed_at'] != null ? DateTime.parse(r['completed_at'] as String) : null,
        items: items,
      ));
    }
    return orders;
  }

  static Future<Order> getOrder(int id) async {
    final database = await db;
    final rows = await database.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Order $id not found');
    final r = rows.first;

    final itemRows = await database.query('order_items', where: 'order_id = ?', whereArgs: [id]);
    final items = itemRows.map((i) => OrderItem(
      id: i['id'] as int,
      productId: i['product_id'] as int,
      productName: i['product_name'] as String,
      quantity: i['quantity'] as int,
      unitPrice: (i['unit_price'] as num).toDouble(),
      subtotal: (i['subtotal'] as num).toDouble(),
    )).toList();

    return Order(
      id: r['id'] as int,
      orderNumber: r['order_number'] as String,
      status: r['status'] as String,
      subtotal: (r['subtotal'] as num).toDouble(),
      tax: (r['tax'] as num).toDouble(),
      discount: (r['discount'] as num).toDouble(),
      total: (r['total'] as num).toDouble(),
      paymentMethod: r['payment_method'] as String?,
      customerName: r['customer_name'] as String?,
      tableNumber: r['table_number'] as String?,
      notes: r['notes'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
      completedAt: r['completed_at'] != null ? DateTime.parse(r['completed_at'] as String) : null,
      items: items,
    );
  }

  // ─── Sales ────────────────────────────────────────────────────────────────

  static Future<List<SaleRecord>> getSales({String? startDate, String? endDate}) async {
    final database = await db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add("date(sold_at) >= date(?)");
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add("date(sold_at) <= date(?)");
      args.add(endDate);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final rows = await database.rawQuery('SELECT * FROM sale_records $where ORDER BY id DESC', args);

    return rows.map((r) => SaleRecord(
      id: r['id'] as int,
      orderId: r['order_id'] as int,
      orderNumber: r['order_number'] as String,
      total: (r['total'] as num).toDouble(),
      paymentMethod: r['payment_method'] as String,
      customerName: r['customer_name'] as String?,
      tableNumber: r['table_number'] as String?,
      itemCount: r['item_count'] as int,
      soldAt: DateTime.parse(r['sold_at'] as String),
    )).toList();
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  static Future<DashboardSummary> getDashboardSummary() async {
    final database = await db;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final salesToday = await database.rawQuery(
      "SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count FROM sale_records WHERE date(sold_at) = ?",
      [todayStr],
    );

    final totalSalesToday = (salesToday.first['total'] as num).toDouble();
    final totalOrdersToday = salesToday.first['count'] as int;
    final averageOrderValue = totalOrdersToday > 0 ? totalSalesToday / totalOrdersToday : 0.0;

    final pending = await database.rawQuery(
      "SELECT COUNT(*) as c FROM orders WHERE status = 'pending'",
    );
    final completed = await database.rawQuery(
      "SELECT COUNT(*) as c FROM orders WHERE status = 'completed'",
    );
    final cancelled = await database.rawQuery(
      "SELECT COUNT(*) as c FROM orders WHERE status = 'cancelled'",
    );

    return DashboardSummary(
      totalSalesToday: totalSalesToday,
      totalOrdersToday: totalOrdersToday,
      averageOrderValue: averageOrderValue,
      pendingOrders: pending.first['c'] as int,
      completedOrders: completed.first['c'] as int,
      cancelledOrders: cancelled.first['c'] as int,
    );
  }

  static Future<List<TopProduct>> getTopProducts() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT
        oi.product_id,
        oi.product_name,
        SUM(oi.quantity) as qty_sold,
        SUM(oi.subtotal) as revenue
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.status = 'completed'
      GROUP BY oi.product_id, oi.product_name
      ORDER BY qty_sold DESC
      LIMIT 10
    ''');

    return rows.map((r) => TopProduct(
      productId: r['product_id'] as int,
      productName: r['product_name'] as String,
      quantitySold: (r['qty_sold'] as num).toInt(),
      revenue: (r['revenue'] as num).toDouble(),
    )).toList();
  }

  static Future<List<HourlySales>> getHourlySales() async {
    final database = await db;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final rows = await database.rawQuery('''
      SELECT
        CAST(strftime('%H', sold_at) AS INTEGER) as hour,
        SUM(total) as sales,
        COUNT(*) as orders
      FROM sale_records
      WHERE date(sold_at) = ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [todayStr]);

    final Map<int, HourlySales> map = {};
    for (final r in rows) {
      final h = r['hour'] as int;
      map[h] = HourlySales(
        hour: h,
        sales: (r['sales'] as num).toDouble(),
        orders: r['orders'] as int,
      );
    }

    return List.generate(24, (h) => map[h] ?? HourlySales(hour: h, sales: 0, orders: 0));
  }
}
