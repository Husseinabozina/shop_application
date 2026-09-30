import 'package:flutter/foundation.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartModel> _items = {};

  Map<String, CartModel> get items => Map.unmodifiable(_items);

  int get cartLength => _items.length;

  double get totalPrice {
    return _items.values.fold<double>(
      0,
      (total, item) =>
          total + (item.price ?? 0).toDouble() * (item.quantity ?? 0),
    );
  }

  void addItem(String productId, num price, String title) {
    final existing = _items[productId];

    if (existing != null) {
      _items[productId] = CartModel(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: (existing.quantity ?? 0) + 1,
      );
    } else {
      _items[productId] = CartModel(
        id: DateTime.now().toIso8601String(),
        title: title,
        price: price,
        quantity: 1,
      );
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  void removeSingleItem(String productId) {
    final existing = _items[productId];
    if (existing == null) {
      return;
    }

    final quantity = existing.quantity ?? 0;
    if (quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = CartModel(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: quantity - 1,
      );
    }

    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    notifyListeners();
  }
}
