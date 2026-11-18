import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// FR-05 Add items to cart. Total = price x quantity per item (BR-07).
class Cart extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.values.fold(0, (s, i) => s + i.quantity);
  double get subtotal => _items.values.fold(0, (s, i) => s + i.lineTotal);

  /// Returns false if the product is unavailable (BR-05).
  bool add(Product p, ProductVariant v, {int quantity = 1}) {
    if (!p.available || quantity < 1) return false;
    final item = CartItem.fromProduct(p, v, quantity);
    final existing = _items[item.key];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[item.key] = item;
    }
    notifyListeners();
    return true;
  }

  void setQuantity(String key, int quantity) {
    final item = _items[key];
    if (item == null) return;
    if (quantity <= 0) {
      _items.remove(key);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(String key) {
    _items.remove(key);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Items whose product is now unavailable or deleted. Checkout is blocked
  /// until they are removed (BR-05).
  List<CartItem> unavailableItems(List<Product> products) {
    final availableIds = {for (final p in products) if (p.available) p.id};
    return _items.values.where((i) => !availableIds.contains(i.productId)).toList();
  }
}
