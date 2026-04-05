import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../interfaces/item_repository_interface.dart';
import '../models/item_model.dart';

class SqliteItemRepository implements IItemRepository {
  Database? _database;

  @override
  Future<void> initDB() async {
    if (_database != null) return;
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock_flow.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            storeQuantity INTEGER,
            displayQuantity INTEGER,
            expiryDate TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<List<ItemModel>> getItems() async {
    await initDB();
    final List<Map<String, Object?>> maps = await _database!.query('items');
    return maps.map((map) => ItemModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertItem(ItemModel item) async {
    await initDB();
    await _database!.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    await initDB();
    await _database!.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  @override
  Future<void> deleteItem(int id) async {
    await initDB();
    await _database!.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
