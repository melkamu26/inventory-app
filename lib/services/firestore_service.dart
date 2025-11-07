import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('items');

  Stream<List<Item>> itemsStream() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Item.fromDoc(d)).toList(),
        );
  }

  Future<String> addItem(Item item) async {
    final ref = await _col.add(item.toMap());
    return ref.id;
  }

  Future<void> updateItem(Item item) async {
    if (item.id == null) return;
    await _col.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }
}