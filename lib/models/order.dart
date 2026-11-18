import 'package:cloud_firestore/cloud_firestore.dart';

enum Fulfilment {
  pickup('pickup', 'Pickup'),
  delivery('delivery', 'Delivery');

  const Fulfilment(this.id, this.label);
  final String id;
  final String label;

  static Fulfilment fromId(String? id) =>
      values.firstWhere((f) => f.id == id, orElse: () => pickup);
}

/// Order statuses agreed with the client, in order (BR-01).
enum OrderStatus {
  pending('pending', 'Pending'),
  preparing('preparing', 'Being prepared'),
  ready('ready', 'Ready for pickup'),
  outForDelivery('out_for_delivery', 'Out for delivery'),
  completed('completed', 'Completed');

  const OrderStatus(this.id, this.label);
  final String id;
  final String label;

  static OrderStatus fromId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => pending);

  /// The steps an order goes through for its fulfilment method.
  static List<OrderStatus> flowFor(Fulfilment f) => f == Fulfilment.pickup
      ? const [pending, preparing, ready, completed]
      : const [pending, preparing, outForDelivery, completed];

  /// The statuses the admin may move an order to next.
  static List<OrderStatus> nextOptions(OrderStatus current, Fulfilment f) {
    final flow = flowFor(f);
    final i = flow.indexOf(current);
    if (i < 0) return flow;
    return flow.sublist(i + 1);
  }
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.productId = '',
  });
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  double get lineTotal => unitPrice * quantity;

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        productId: (m['productId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        unitPrice: (m['unitPrice'] as num? ?? 0).toDouble(),
        quantity: (m['quantity'] as num? ?? 0).toInt(),
      );
}

class CnnoOrder {
  const CnnoOrder({
    required this.id,
    required this.number,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.total,
    required this.fulfilment,
    required this.preferredDate,
    required this.preferredTime,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int number;
  final String userId;
  final String customerName;
  final String customerEmail;
  final List<OrderLine> items;
  final double total;
  final Fulfilment fulfilment;
  final DateTime preferredDate;
  final String preferredTime;
  final String phone;
  final String address;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;

  String get label => '#$number';

  factory CnnoOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    DateTime ts(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    return CnnoOrder(
      id: d.id,
      number: (m['number'] as num? ?? 0).toInt(),
      userId: (m['userId'] ?? '') as String,
      customerName: (m['customerName'] ?? '') as String,
      customerEmail: (m['customerEmail'] ?? '') as String,
      items: ((m['items'] as List?) ?? const [])
          .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: (m['total'] as num? ?? 0).toDouble(),
      fulfilment: Fulfilment.fromId(m['fulfilment'] as String?),
      preferredDate: ts(m['preferredDate']),
      preferredTime: (m['preferredTime'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      paymentMethod: (m['paymentMethod'] ?? '') as String,
      status: OrderStatus.fromId(m['status'] as String?),
      createdAt: m['createdAt'] is Timestamp ? ts(m['createdAt']) : DateTime.now(),
    );
  }
}
