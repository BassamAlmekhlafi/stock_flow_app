import '../models/item_model.dart'; // import the ItemModel

abstract class IItemRepository {
  Future<void> initDB();
  Future<List<ItemModel>> getItems();
  Future<void> insertItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem(int id);
}
