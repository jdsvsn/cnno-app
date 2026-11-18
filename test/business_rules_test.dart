import 'package:cnno_app/data/menu_seed.dart';
import 'package:cnno_app/models/order.dart';
import 'package:cnno_app/models/product.dart';
import 'package:cnno_app/services/ai_service.dart';
import 'package:cnno_app/state/cart.dart';
import 'package:cnno_app/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

Product byId(String id) => cnnoMenu.firstWhere((p) => p.id == id);

void main() {
  group('Menu (CLAUDE.md final menu)', () {
    test('has the agreed prices', () {
      expect(byId('og-cinnamon').minPrice, 8);
      expect(byId('chocolate').minPrice, 10);
      expect(byId('pistachio').minPrice, 11);
      expect(byId('baby-rolls').variants.map((v) => v.price), [14, 16, 17]);
      expect(byId('duo-box').variants.map((v) => v.price), [15, 19, 20, 17, 18, 20]);
      expect(byId('party-box').variants.map((v) => v.price), [54, 63, 72]);
    });

    test('does not contain Gula Apong (removed by the client)', () {
      final text = cnnoMenu
          .map((p) => '${p.name} ${p.description} ${p.variants.map((v) => v.name).join(' ')}')
          .join(' ')
          .toLowerCase();
      expect(text.contains('gula'), isFalse);
      expect(text.contains('apong'), isFalse);
    });

    test('price labels', () {
      expect(byId('og-cinnamon').priceLabel, 'RM 8.00');
      expect(byId('baby-rolls').priceLabel, 'From RM 14.00');
      expect(byId('duo-box').priceRangeLabel, 'RM 15 to 20');
    });
  });

  group('Cart (FR-05, BR-05, BR-07)', () {
    test('total is price x quantity per item', () {
      final cart = Cart()
        ..add(byId('og-cinnamon'), byId('og-cinnamon').variants.first, quantity: 2)
        ..add(byId('pistachio'), byId('pistachio').variants.first)
        ..add(byId('duo-box'), byId('duo-box').variants[4]); // OG + Pista RM 18
      expect(cart.subtotal, 16 + 11 + 18);
      expect(cart.count, 4);
    });

    test('adding the same item again increases its quantity', () {
      final p = byId('chocolate');
      final cart = Cart()..add(p, p.variants.first)..add(p, p.variants.first, quantity: 2);
      expect(cart.items.single.quantity, 3);
    });

    test('unavailable product cannot be added', () {
      final p = byId('chocolate').copyWith(available: false);
      final cart = Cart();
      expect(cart.add(p, p.variants.first), isFalse);
      expect(cart.isEmpty, isTrue);
    });

    test('items that became unavailable block checkout', () {
      final p = byId('pistachio');
      final cart = Cart()..add(p, p.variants.first);
      final now = cnnoMenu.map((x) => x.id == p.id ? x.copyWith(available: false) : x).toList();
      expect(cart.unavailableItems(now).single.productId, p.id);
      expect(cart.unavailableItems(cnnoMenu), isEmpty);
    });

    test('quantity 0 removes the item', () {
      final p = byId('og-cinnamon');
      final cart = Cart()..add(p, p.variants.first);
      cart.setQuantity(cart.items.single.key, 0);
      expect(cart.isEmpty, isTrue);
    });
  });

  group('Preorder date (FR-07, BR-03)', () {
    test('earliest date is today plus the lead time', () {
      final now = DateTime(2026, 11, 18, 21, 30);
      expect(earliestPreorderDate(now, 1), DateTime(2026, 11, 19));
      expect(earliestPreorderDate(now, 0), DateTime(2026, 11, 18));
    });
  });

  group('Order status flow (BR-01)', () {
    test('pickup orders skip Out for delivery', () {
      expect(OrderStatus.flowFor(Fulfilment.pickup), [
        OrderStatus.pending,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.completed,
      ]);
    });

    test('delivery orders skip Ready for pickup', () {
      expect(OrderStatus.flowFor(Fulfilment.delivery), [
        OrderStatus.pending,
        OrderStatus.preparing,
        OrderStatus.outForDelivery,
        OrderStatus.completed,
      ]);
    });

    test('admin can only move an order forward', () {
      expect(OrderStatus.nextOptions(OrderStatus.preparing, Fulfilment.delivery),
          [OrderStatus.outForDelivery, OrderStatus.completed]);
      expect(OrderStatus.nextOptions(OrderStatus.completed, Fulfilment.pickup), isEmpty);
    });
  });

  group('Recommendation fallback (FR-AI-01)', () {
    test('suggests a single roll the customer has not ordered, preferring favourites', () {
      final r = AiService.fallbackRecommendation(cnnoMenu, ['Pistachio'], ['og-cinnamon']);
      expect(r!.product.id, 'pistachio');
      expect(r.fromAi, isFalse);
    });

    test('never suggests an unavailable product', () {
      final available = cnnoMenu.where((p) => p.id != 'og-cinnamon').toList();
      final r = AiService.fallbackRecommendation(available, const [], const []);
      expect(r!.product.id, isNot('og-cinnamon'));
    });
  });
}
