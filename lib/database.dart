import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StockDatabase {
  static final StockDatabase instance = StockDatabase._init();
  static Database? _database;

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
    await db.execute('''
      CREATE TABLE stock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      );
    ''');

    // ✅ Beers
    await db.insert("stock", {
      "name": "Castle Lager",
      "price": 29.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Heineken",
      "price": 35.0,
      "quantity": 20,
    });
    await db.insert("stock", {"name": "Corona", "price": 40.0, "quantity": 20});

    // ✅ Ciders
    await db.insert("stock", {
      "name": "Savanna Dry",
      "price": 32.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Hunters Gold",
      "price": 30.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Brutal Fruit",
      "price": 28.0,
      "quantity": 20,
    });

    // ✅ Vodka
    await db.insert("stock", {
      "name": "Smirnoff Vodka (Single)",
      "price": 25.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Absolut Vodka (Single)",
      "price": 35.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Belvedere (Single)",
      "price": 50.0,
      "quantity": 20,
    });

    // ✅ Rums
    await db.insert("stock", {
      "name": "Captain Morgan",
      "price": 28.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Bacardi White Rum",
      "price": 30.0,
      "quantity": 20,
    });

    // ✅ Whiskies
    await db.insert("stock", {
      "name": "Jameson (Single)",
      "price": 35.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Jack Daniels (Single)",
      "price": 38.0,
      "quantity": 20,
    });
    await db.insert("stock", {
      "name": "Glenfiddich 12 (Single)",
      "price": 55.0,
      "quantity": 20,
    });

    // ✅ Soft Drinks
    await db.insert("stock", {"name": "Coke", "price": 15.0, "quantity": 30});
    await db.insert("stock", {"name": "Sprite", "price": 15.0, "quantity": 30});
    await db.insert("stock", {
      "name": "Tonic Water",
      "price": 18.0,
      "quantity": 30,
    });
    await db.insert("stock", {
      "name": "Ginger Ale",
      "price": 18.0,
      "quantity": 30,
    });
  }

  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "stock.db");
    try {
      await deleteDatabase(path);
    } catch (e) {
      // ignore or log
      print("Failed to delete DB: $e");
    }
    _database = null;
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

    if (item == null) return false;
    if (item["quantity"] <= 0) return false;

    await db.update(
      "stock",
      {"quantity": item["quantity"] - 1},
      where: "name = ?",
      whereArgs: [name],
    );

    return true;
  }
}
