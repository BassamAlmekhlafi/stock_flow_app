import '../interfaces/item_repository_interface.dart';
import '../models/item_model.dart';

class WebItemRepository implements IItemRepository {
  final List<ItemModel> _items = [];
  int _currentId = 1;

  @override
  Future<void> initDB() async {
    // الويب في هذه النسخة يستخدم الذاكرة (In-Memory) لتجنب مشاكل التوافق
  }

  @override
  Future<List<ItemModel>> getItems() async {
    return _items;
  }

  @override
  Future<void> insertItem(ItemModel item) async {
    item.id = _currentId++;
    _items.add(item);
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem(int id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
