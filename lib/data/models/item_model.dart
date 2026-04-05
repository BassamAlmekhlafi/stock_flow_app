class ItemModel {
  int? id;
  String name;
  int storeQuantity; // المخازن
  int displayQuantity; // العرض
  
  // النظام = العرض + المخازن (محسوب تلقائياً)
  int get systemQuantity => storeQuantity + displayQuantity;
  
  DateTime expiryDate;

  ItemModel({
    this.id,
    required this.name,
    required this.storeQuantity,
    required this.displayQuantity,
    required this.expiryDate,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'storeQuantity': storeQuantity,
      'displayQuantity': displayQuantity,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      storeQuantity: map['storeQuantity'] as int,
      displayQuantity: map['displayQuantity'] as int,
      expiryDate: DateTime.parse(map['expiryDate'] as String),
    );
  }
}
