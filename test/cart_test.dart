import 'package:cnno_app/data/menu_seed.dart';
import 'package:cnno_app/models/cart_item.dart';
import 'package:cnno_app/models/product.dart';
import 'package:cnno_app/state/cart.dart';
import 'package:flutter_test/flutter_test.dart';

Product byId(String id) => cnnoMenu.firstWhere((p) => p.id == id);

void main() {
  group('Cart (FR-05)', () {
    test('different box options are separate cart lines', () {
      final duo = byId('duo-box');
      final cart = Cart()
        ..add(duo, duo.variants[0]) // OG + OG RM 15
        ..add(duo, duo.variants[5]); // Choco + Pista RM 20
      expect(cart.items.length, 2);
      expect(cart.subtotal, 35);
    });

    test('quantity below 1 is refused', () {
      final p = byId('og-cinnamon');
      final cart = Cart();
      expect(cart.add(p, p.variants.first, quantity: 0), isFalse);
      expect(cart.isEmpty, isTrue);
    });

    test('remove and clear empty the cart', () {
      final og = byId('og-cinnamon');
      final party = byId('party-box');
      final cart = Cart()
        ..add(og, og.variants.first)
        ..add(party, party.variants.first);
      cart.remove(cart.items.first.key);
      expect(cart.items.single.productId, 'party-box');
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0);
    });

    test('setQuantity on an unknown key does nothing', () {
      final p = byId('chocolate');
      final cart = Cart()..add(p, p.variants.first);
      cart.setQuantity('missing|key', 5);
      expect(cart.count, 1);
    });

    test('notifies listeners when it changes', () {
      final p = byId('pistachio');
      final cart = Cart();
      var calls = 0;
      cart.addListener(() => calls++);
      cart.add(p, p.variants.first);
      cart.setQuantity(cart.items.single.key, 3);
      cart.clear();
      expect(calls, 3);
    });

    test('deleted products also block checkout', () {
      final p = byId('baby-rolls');
      final cart = Cart()..add(p, p.variants.first);
      final withoutBaby = cnnoMenu.where((x) => x.id != 'baby-rolls').toList();
      expect(cart.unavailableItems(withoutBaby).single.productId, 'baby-rolls');
    });
  });

  group('CartItem', () {
    test('single rolls show only the product name', () {
      final p = byId('og-cinnamon');
      final item = CartItem.fromProduct(p, p.variants.first, 1);
      expect(item.displayName, 'OG Cinnamon Roll');
    });

    test('boxes show the chosen option', () {
      final p = byId('duo-box');
      final item = CartItem.fromProduct(p, p.variants[4], 2);
      expect(item.displayName, 'Duo Box (OG + Pista)');
      expect(item.key, 'duo-box|OG + Pista');
    });

    test('toOrderMap stores what the order and receipt need', () {
      final p = byId('party-box');
      final item = CartItem.fromProduct(p, p.variants[2], 2); // Pista RM 72
      expect(item.toOrderMap(), {
        'productId': 'party-box',
        'name': 'Party Box (Pista)',
        'unitPrice': 72.0,
        'quantity': 2,
        'lineTotal': 144.0,
      });
    });
  });
}
