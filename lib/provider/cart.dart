import 'package:flutter/foundation.dart';

class CartItem {
  final String? id;
  final String? title;
  final double? quantitiy;
  final num? price;
  CartItem(
      {required this.id,
      required this.title,
      this.quantitiy,
      required this.price});
}

class Cart with ChangeNotifier {
  Map<String, CartItem>? _items = {};
  Map<String, CartItem> get Items {
    return {..._items!};
  }

  double get totalPrice {
    double total = 0.0;
    _items!.forEach((key, value) {
      total += value.price! * value.quantitiy!.toDouble();
    });
    return total;
  }

  void addItem(String productId, num price, String title) {
    if (_items!.containsKey(productId)) {
      _items!.update(
          productId,
          (existencartItem) => CartItem(
              id: existencartItem.id,
              title: existencartItem.title,
              price: existencartItem.price,
              quantitiy: existencartItem.quantitiy! + 1));
    } else {
      _items!.putIfAbsent(
          productId,
          () => CartItem(
              id: DateTime.now().toString(),
              title: title,
              price: price,
              quantitiy: 1));
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
    } else if (_items![productId]!.quantitiy! > 1) {
      _items!.update(
          productId,
          (existingCartItem) => CartItem(
              id: existingCartItem.id,
              title: existingCartItem.title,
              price: existingCartItem.price,
              quantitiy: existingCartItem.quantitiy! - 1));
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
