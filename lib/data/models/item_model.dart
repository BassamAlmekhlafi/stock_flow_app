class ItemModel {
  int? id;
  String name;
  int storeQuantity; // المخازن
  int displayQuantity; // العرض
  
  int systemQuantity; // النظام (إدخال يدوي)
  
  DateTime expiryDate;

  ItemModel({
    this.id,
    required this.name,
    required this.storeQuantity,
    required this.displayQuantity,
    required this.systemQuantity,
    required this.expiryDate,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'storeQuantity': storeQuantity,
      'displayQuantity': displayQuantity,
      'systemQuantity': systemQuantity,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      storeQuantity: map['storeQuantity'] as int,
      displayQuantity: map['displayQuantity'] as int,
      systemQuantity: map['systemQuantity'] as int? ?? 0, // Fallback for old data
      expiryDate: DateTime.parse(map['expiryDate'] as String),
    );
  }
}
