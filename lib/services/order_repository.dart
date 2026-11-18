import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// FR-06 to FR-09, FR-12 to FR-14.
class OrderRepository {
  OrderRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('orders');

  /// Places an order with the next order number (#1001, #1002, ...).
  /// The Cloud Function `sendReceipt` emails the receipt (FR-10).
  Future<String> placeOrder({
    required AppUser user,
    required List<CartItem> items,
    required Fulfilment fulfilment,
    required DateTime preferredDate,
    required String preferredTime,
    required String phone,
    required String address,
    required String paymentMethod,
  }) async {
    final counter = _db.collection('counters').doc('orders');
    final orderRef = _col.doc();
    final total = items.fold<double>(0, (s, i) => s + i.lineTotal);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(counter);
      final current = snap.exists ? (snap.data()!['next'] as num).toInt() : 1000;
      final number = current + 1;
      tx.set(counter, {'next': number});
      tx.set(orderRef, {
        'number': number,
        'userId': user.uid,
        'customerName': user.name,
        'customerEmail': user.email,
        'items': items.map((i) => i.toOrderMap()).toList(),
        'total': total,
        'fulfilment': fulfilment.id,
        'preferredDate': Timestamp.fromDate(preferredDate),
        'preferredTime': preferredTime,
        'phone': phone,
        'address': fulfilment == Fulfilment.delivery ? address : '',
        'paymentMethod': paymentMethod,
        'status': OrderStatus.pending.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return orderRef.id;
  }

  Stream<CnnoOrder> watchOrder(String id) =>
      _col.doc(id).snapshots().map(CnnoOrder.fromDoc);

  /// FR-14: the customer's orders, newest first.
  Stream<List<CnnoOrder>> watchMyOrders(String uid) => _col
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(s.docs.map(CnnoOrder.fromDoc).toList()));

  /// FR-12, FR-13: all orders for the admin.
  Stream<List<CnnoOrder>> watchAllOrders() =>
      _col.snapshots().map((s) => _sorted(s.docs.map(CnnoOrder.fromDoc).toList()));

  Future<void> updateStatus(String id, OrderStatus status) => _col.doc(id).update({
        'status': status.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static List<CnnoOrder> _sorted(List<CnnoOrder> list) =>
      list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
