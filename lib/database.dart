import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

class StockDatabase {
  static final StockDatabase instance = StockDatabase._init();
  static Database? _database;

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
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      );
    ''');

    // Stock with category
    await db.execute('''
      CREATE TABLE stock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        category TEXT NOT NULL
      );
    ''');

    // Sales history
    await db.execute('''
      CREATE TABLE sales_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');

    // Default users
    await db.insert("users", {
      "username": "admin",
      "password": "admin123",
      "role": "admin",
    });
    await db.insert("users", {
      "username": "bartender",
      "password": "bartender123",
      "role": "bartender",
    });

    // Initial stock items
    final items = [
      {
        "name": "Castle Lager",
        "price": 29.0,
        "quantity": 20,
        "category": "Beers",
      },
      {"name": "Heineken", "price": 35.0, "quantity": 20, "category": "Beers"},
      {"name": "Corona", "price": 40.0, "quantity": 20, "category": "Beers"},
      {
        "name": "Savanna Dry",
        "price": 32.0,
        "quantity": 20,
        "category": "Ciders",
      },
      {
        "name": "Hunters Gold",
        "price": 30.0,
        "quantity": 20,
        "category": "Ciders",
      },
      {
        "name": "Brutal Fruit",
        "price": 28.0,
        "quantity": 20,
        "category": "Ciders",
      },
      {
        "name": "Smirnoff Vodka (Single)",
        "price": 25.0,
        "quantity": 20,
        "category": "Vodka",
      },
      {
        "name": "Absolut Vodka (Single)",
        "price": 35.0,
        "quantity": 20,
        "category": "Vodka",
      },
      {
        "name": "Belvedere (Single)",
        "price": 50.0,
        "quantity": 20,
        "category": "Vodka",
      },
      {
        "name": "Captain Morgan",
        "price": 28.0,
        "quantity": 20,
        "category": "Rums",
      },
      {
        "name": "Bacardi White Rum",
        "price": 30.0,
        "quantity": 20,
        "category": "Rums",
      },
      {
        "name": "Jameson (Single)",
        "price": 35.0,
        "quantity": 20,
        "category": "Whiskies",
      },
      {
        "name": "Jack Daniels (Single)",
        "price": 38.0,
        "quantity": 20,
        "category": "Whiskies",
      },
      {
        "name": "Glenfiddich 12 (Single)",
        "price": 55.0,
        "quantity": 20,
        "category": "Whiskies",
      },
      {
        "name": "Coke",
        "price": 15.0,
        "quantity": 30,
        "category": "Soft Drinks",
      },
      {
        "name": "Sprite",
        "price": 15.0,
        "quantity": 30,
        "category": "Soft Drinks",
      },
      {
        "name": "Tonic Water",
        "price": 18.0,
        "quantity": 30,
        "category": "Soft Drinks",
      },
      {
        "name": "Ginger Ale",
        "price": 18.0,
        "quantity": 30,
        "category": "Soft Drinks",
      },
    ];

    for (var item in items) await db.insert("stock", item);
  }

  /// LOGIN
  Future<String?> validateUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      "users",
      where: "username = ? AND password = ?",
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? result.first["role"] as String : null;
  }

  /// CRUD FOR DRINKS
  Future<void> addNewDrink(
    String name,
    double price,
    int quantity,
    String category,
  ) async {
    final db = await database;
    await db.insert("stock", {
      "name": name,
      "price": price,
      "quantity": quantity,
      "category": category,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeDrink(int id) async {
    final db = await database;
    await db.delete("stock", where: "id = ?", whereArgs: [id]);
  }

  Future<void> restockDrink(int id, int newStock) async {
    final db = await database;
    await db.update(
      "stock",
      {"quantity": newStock},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> fetchStock() async {
    final db = await instance.database;
    return await db.query("stock");
  }

  Future<Map<String, dynamic>?> findItem(String name) async {
    final db = await instance.database;
    final result = await db.query(
      "stock",
      where: "name = ?",
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

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
    return true;
  }

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
  }

  /// SALES HISTORY
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
  }

  Future<List<Map<String, dynamic>>> fetchSalesHistory() async {
    final db = await instance.database;
    return await db.query("sales_history", orderBy: "timestamp DESC");
  }

  Future<void> clearSalesHistory() async {
    final db = await instance.database;
    await db.delete("sales_history");
  }

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
}
