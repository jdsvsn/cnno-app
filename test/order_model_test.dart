import 'package:cnno_app/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fulfilment (FR-08)', () {
    test('parses stored ids', () {
      expect(Fulfilment.fromId('pickup'), Fulfilment.pickup);
      expect(Fulfilment.fromId('delivery'), Fulfilment.delivery);
    });

    test('unknown or missing id falls back to pickup', () {
      expect(Fulfilment.fromId(null), Fulfilment.pickup);
      expect(Fulfilment.fromId('drone'), Fulfilment.pickup);
    });
  });

  group('OrderStatus (FR-09, BR-01)', () {
    test('every status round-trips through its id', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromId(s.id), s);
      }
    });

    test('unknown or missing id falls back to Pending', () {
      expect(OrderStatus.fromId(null), OrderStatus.pending);
      expect(OrderStatus.fromId('lost'), OrderStatus.pending);
    });

    test('labels match the statuses agreed with the client', () {
      expect(OrderStatus.values.map((s) => s.label), [
        'Pending',
        'Being prepared',
        'Ready for pickup',
        'Out for delivery',
        'Completed',
      ]);
    });

    test('every flow starts at Pending and ends at Completed', () {
      for (final f in Fulfilment.values) {
        final flow = OrderStatus.flowFor(f);
        expect(flow.first, OrderStatus.pending);
        expect(flow.last, OrderStatus.completed);
      }
    });

    test('a new order can move to any later step', () {
      expect(OrderStatus.nextOptions(OrderStatus.pending, Fulfilment.pickup), [
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.completed,
      ]);
    });

    test('a status outside the flow offers the whole flow', () {
      // e.g. a pickup order wrongly marked Out for delivery.
      expect(
        OrderStatus.nextOptions(OrderStatus.outForDelivery, Fulfilment.pickup),
        OrderStatus.flowFor(Fulfilment.pickup),
      );
    });
  });

  group('OrderLine', () {
    test('line total is unit price x quantity', () {
      const line = OrderLine(name: 'Duo Box (OG + Pista)', unitPrice: 18, quantity: 3);
      expect(line.lineTotal, 54);
    });

    test('fromMap reads stored fields and tolerates missing ones', () {
      final line = OrderLine.fromMap({
        'productId': 'chocolate',
        'name': 'Chocolate Roll',
        'unitPrice': 10,
        'quantity': 2,
      });
      expect(line.productId, 'chocolate');
      expect(line.unitPrice, 10.0);
      expect(line.lineTotal, 20);

      final empty = OrderLine.fromMap({});
      expect(empty.name, '');
      expect(empty.quantity, 0);
      expect(empty.lineTotal, 0);
    });
  });
}
