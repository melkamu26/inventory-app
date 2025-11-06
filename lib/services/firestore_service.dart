import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _col = FirebaseFirestore.instance.collection('items').withConverter(
        fromFirestore: (snap, _) => Item.fromDoc(snap),
        toFirestore: (item, _) => item.toMap(),
      );

  // Add
  Future<void> addItem(Item item) => _col.add(item);

  // Update
  Future<void> updateItem(Item item) =>
      _col.doc(item.id!).set(item, SetOptions(merge: true));

  // Delete
  Future<void> deleteItem(String id) => _col.doc(id).delete();

  // Stream with filters
  // Search: prefix match on name_lc
  // Category: exact
  // Price: min/max
  Stream<List<Item>> itemsStream({
    String search = '',
    String category = 'All',
    double? minPrice,
    double? maxPrice,
  }) {
    Query<Item> q = _col;

    // category filter
    if (category != 'All') {
      q = q.where('category', isEqualTo: category);
    }

    // price range filter
    if (minPrice != null) {
      q = q.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      q = q.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (minPrice != null || maxPrice != null) {
      q = q.orderBy('price'); // required when using price range
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    // name prefix search using name_lc bounds
    final s = search.trim().toLowerCase();
    if (s.isNotEmpty) {
      // Firestore requires range on same field be ordered by same field
      q = _col; // rebuild to ensure correct orderBy
      if (category != 'All') q = q.where('category', isEqualTo: category);
      if (minPrice != null) q = q.where('price', isGreaterThanOrEqualTo: minPrice);
      if (maxPrice != null) q = q.where('price', isLessThanOrEqualTo: maxPrice);

      // When mixing price range + name range, a composite index might be needed.
      q = q
          .where('name_lc', isGreaterThanOrEqualTo: s)
          .where('name_lc', isLessThanOrEqualTo: '$s\uf8ff')
          .orderBy('name_lc');
    }

    return q.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}