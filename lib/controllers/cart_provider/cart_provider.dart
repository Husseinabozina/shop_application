import 'package:flutter/foundation.dart';

import '../../data/models/cart/cart_model.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartModel>? _items = {};
  Map<String, CartModel> get Items {
    return {..._items!};
  }

  double get totalPrice {
    double total = 0.0;
    _items!.forEach((key, value) {
      total += value.price! * value.quantity!.toDouble();
    });
    return total;
  }

  void addItem(String productId, num price, String title) {
    if (_items!.containsKey(productId)) {
      _items!.update(
          productId,
          (existencartItem) => CartModel(
              id: existencartItem.id,
              title: existencartItem.title,
              price: existencartItem.price,
              quantity: existencartItem.quantity! + 1));
    } else {
      _items!.putIfAbsent(
          productId,
          () => CartModel(
              id: DateTime.now().toString(),
              title: title,
              price: price,
              quantity: 1));
    }
    notifyListeners();
  }

  int get cartlengh {
    return _items == null ? 0 : _items!.length;
  }

  void removeItem(String productId) {
    _items!.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items!.containsKey(productId)) {
      return;
    } else if (_items![productId]!.quantity! > 1) {
      _items!.update(
          productId,
          (existingCartItem) => CartModel(
              id: existingCartItem.id,
              title: existingCartItem.title,
              price: existingCartItem.price,
              quantity: existingCartItem.quantity! - 1));
    } else {
      removeItem(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
