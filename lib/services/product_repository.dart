import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/menu_seed.dart';
import '../models/product.dart';

/// FR-03, FR-04 (customer) and FR-11 (admin).
class ProductRepository {
  ProductRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage; // ignore: prefer_initializing_formals

  final FirebaseFirestore _db;
  final FirebaseStorage? _storage;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('products');

  Stream<List<Product>> watchAll() => _col.snapshots().map((s) {
        final list = s.docs.map(Product.fromDoc).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      });

  Future<void> setAvailable(String id, bool available) =>
      _col.doc(id).update({'available': available});

  Future<void> save(Product p) {
    final ref = p.id.isEmpty ? _col.doc() : _col.doc(p.id);
    return ref.set(p.toMap());
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Uploads an admin photo to Cloud Storage and returns its download URL.
  Future<String> uploadPhoto(Uint8List bytes) async {
    final storage = _storage ?? FirebaseStorage.instance;
    final ref = storage
        .ref('products/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Writes the agreed menu (admin only, allowed by security rules).
  Future<void> seedMenu() async {
    final batch = _db.batch();
    for (final p in cnnoMenu) {
      batch.set(_col.doc(p.id), p.toMap());
    }
    await batch.commit();
  }
}
