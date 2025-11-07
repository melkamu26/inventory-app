import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final String name;
  final int quantity;
  final double price;
  final String category;
  final DateTime createdAt;

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Item(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      quantity: (d['quantity'] ?? 0) as int,
      price: (d['price'] is int)
          ? (d['price'] as int).toDouble()
          : (d['price'] ?? 0.0) as double,
      category: (d['category'] ?? '') as String,
      createdAt:
          (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}