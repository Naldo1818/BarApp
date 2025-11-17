import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

class StockDatabase {
  static final StockDatabase instance = StockDatabase._init();
  static Database? _database;

  // Logger for production-safe logging
  final Logger logger = Logger('StockDatabase');

  StockDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("stock.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Stock table
    await db.execute('''
      CREATE TABLE stock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      );
    ''');

    // Sales history table
    await db.execute('''
      CREATE TABLE sales_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');

    // Initial stock items
    final items = [
      {"name": "Castle Lager", "price": 29.0, "quantity": 20},
      {"name": "Heineken", "price": 35.0, "quantity": 20},
      {"name": "Corona", "price": 40.0, "quantity": 20},

      {"name": "Savanna Dry", "price": 32.0, "quantity": 20},
      {"name": "Hunters Gold", "price": 30.0, "quantity": 20},
      {"name": "Brutal Fruit", "price": 28.0, "quantity": 20},

      {"name": "Smirnoff Vodka (Single)", "price": 25.0, "quantity": 20},
      {"name": "Absolut Vodka (Single)", "price": 35.0, "quantity": 20},
      {"name": "Belvedere (Single)", "price": 50.0, "quantity": 20},

      {"name": "Captain Morgan", "price": 28.0, "quantity": 20},
      {"name": "Bacardi White Rum", "price": 30.0, "quantity": 20},

      {"name": "Jameson (Single)", "price": 35.0, "quantity": 20},
      {"name": "Jack Daniels (Single)", "price": 38.0, "quantity": 20},
      {"name": "Glenfiddich 12 (Single)", "price": 55.0, "quantity": 20},

      {"name": "Coke", "price": 15.0, "quantity": 30},
      {"name": "Sprite", "price": 15.0, "quantity": 30},
      {"name": "Tonic Water", "price": 18.0, "quantity": 30},
      {"name": "Ginger Ale", "price": 18.0, "quantity": 30},
    ];

    for (var item in items) {
      await db.insert("stock", item);
    }
  }

  /// Deletes the database
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "stock.db");
    try {
      await deleteDatabase(path);
    } catch (e) {
      logger.warning("Failed to delete DB: $e");
    }
    _database = null;
  }

  /// Fetch all stock items
  Future<List<Map<String, dynamic>>> fetchStock() async {
    final db = await instance.database;
    return await db.query("stock");
  }

  /// Find a specific item
  Future<Map<String, dynamic>?> findItem(String name) async {
    final db = await instance.database;
    final result = await db.query(
      "stock",
      where: "name = ?",
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Reduce stock of a specific item by 1
  Future<bool> reduceStock(String name) async {
    final db = await instance.database;
    final item = await findItem(name);

    if (item == null || item["quantity"] <= 0) return false;

    await db.update(
      "stock",
      {"quantity": item["quantity"] - 1},
      where: "name = ?",
      whereArgs: [name],
    );

    logger.info("Reduced stock for $name by 1");
    return true;
  }

  /// Increase stock of a specific item
  Future<void> increaseStock(String name, int amount) async {
    final db = await instance.database;
    final item = await findItem(name);
    if (item == null) return;

    await db.update(
      "stock",
      {"quantity": item["quantity"] + amount},
      where: "name = ?",
      whereArgs: [name],
    );

    logger.info("Increased stock for $name by $amount");
  }

  /// Record a sale for each item in the cart
  Future<void> recordSale(Map<String, Map<String, dynamic>> cart) async {
    final db = await instance.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    cart.forEach((name, meta) {
      final qty = meta["quantity"] as int;
      final price = (meta["price"] as num).toDouble();
      final total = price * qty;
      batch.insert("sales_history", {
        "item": name,
        "quantity": qty,
        "total_price": total,
        "timestamp": now,
      });
    });

    await batch.commit(noResult: true);
    logger.info("Recorded sale for ${cart.length} items");
  }

  /// Fetch sales history (most recent first)
  Future<List<Map<String, dynamic>>> fetchSalesHistory() async {
    final db = await instance.database;
    return await db.query("sales_history", orderBy: "timestamp DESC");
  }

  /// Clear all sales history
  Future<void> clearSalesHistory() async {
    final db = await instance.database;
    await db.delete("sales_history");
    logger.info("Cleared sales history");
  }
}
