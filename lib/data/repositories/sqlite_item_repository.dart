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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            storeQuantity INTEGER,
            displayQuantity INTEGER,
            systemQuantity INTEGER,
            expiryDate TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE items ADD COLUMN systemQuantity INTEGER DEFAULT 0');
        }
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

  @override
  Future<void> upsertItems(List<ItemModel> items) async {
    await initDB();
    final batch = _database!.batch();
    for (final item in items) {
      // ابحث عن صنف بنفس الاسم
      final existing = await _database!.query(
        'items',
        where: 'name = ?',
        whereArgs: [item.name],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        // تحديث الصنف الموجود مع الاحتفاظ بالـ id
        final existingId = existing.first['id'] as int;
        batch.update(
          'items',
          {
            'storeQuantity': item.storeQuantity,
            'displayQuantity': item.displayQuantity,
            'systemQuantity': item.systemQuantity,
            'expiryDate': item.expiryDate.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );
      } else {
        // إضافة الصنف الجديد
        final map = item.toMap()..remove('id');
        batch.insert('items', map);
      }
    }
    await batch.commit(noResult: true);
  }
}
