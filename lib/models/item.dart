import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final String name;
  final int quantity;
  final double price;
  final String category;
  final DateTime createdAt;

  // lowercased name for search
  String get nameLc => name.toLowerCase();

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'name_lc': nameLc,
        'quantity': quantity,
        'price': price,
        'category': category,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Item(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      quantity: (data['quantity'] ?? 0) as int,
      price: (data['price'] ?? 0.0).toDouble(),
      category: (data['category'] ?? 'General') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}