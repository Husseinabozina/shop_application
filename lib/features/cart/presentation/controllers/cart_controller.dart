import 'package:flutter/foundation.dart';
import 'package:shop_application/features/cart/domain/entities/cart_item.dart';
import 'package:shop_application/features/cart/domain/repositories/cart_repository.dart';

class CartController with ChangeNotifier {
  final CartRepository? repository;
  final String? userId;
  final Map<String, CartItem> _items = {};
  Future<void> _pending = Future.value();
  bool _disposed = false;
  String? persistenceError;

  CartController({this.repository, this.userId}) {
    if (repository != null && userId != null) {
      _items.addAll(repository!.load(userId!));
    }
  }

  Future<void> flush() => _pending;

  void _changed() {
    if (_disposed) return;
    persistenceError = null;
    notifyListeners();
    final store = repository;
    final scope = userId;
    if (store == null || scope == null) return;
    _pending = store.save(scope, Map.of(_items)).catchError((Object error) {
      if (_disposed) return;
      persistenceError = 'Your cart could not be saved on this device. Try again.';
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Map<String, CartItem> get items => Map.unmodifiable(_items);

  int get cartLength => _items.length;

  double get totalPrice {
    return _items.values.fold<double>(
      0,
      (total, item) =>
          total + (item.price ?? 0).toDouble() * (item.quantity ?? 0),
    );
  }

  bool addItem(
    String productId,
    num price,
    String title, {
    double? maxQuantity,
  }) {
    if (maxQuantity != null && maxQuantity <= 0) {
      return false;
    }

    final existing = _items[productId];

    if (existing != null) {
      final currentQuantity = existing.quantity ?? 0;
      if (maxQuantity != null && currentQuantity >= maxQuantity) {
        return false;
      }

      _items[productId] = CartItem(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: currentQuantity + 1,
      );
    } else {
      _items[productId] = CartItem(
        id: DateTime.now().toIso8601String(),
        title: title,
        price: price,
        quantity: 1,
      );
    }

    _changed();
    return true;
  }

  void removeItem(String productId) {
    if (_items.remove(productId) != null) {
      _changed();
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
      _items[productId] = CartItem(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: quantity - 1,
      );
    }

    _changed();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    _changed();
  }
}
