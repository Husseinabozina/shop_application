import 'dart:convert';

import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/features/cart/domain/entities/cart_item.dart';
import 'package:shop_application/features/cart/domain/repositories/cart_repository.dart';

class LocalCartRepository implements CartRepository {
  final _snapshots = <String, Map<String, CartItem>>{};
  Future<void> _writes = Future.value();

  String _key(String userId) => 'cart_items_v1_$userId';

  @override
  Map<String, CartItem> load(String userId) {
    final pending = _snapshots[userId];
    if (pending != null) return Map.of(pending);
    final items = <String, CartItem>{};
    for (final raw in CacheHelper.getStringList(_key(userId))) {
      try {
        final data = jsonDecode(raw);
        if (data is! Map) continue;
        final productId = data['productId'];
        final title = data['title'];
        final quantity = data['quantity'];
        final price = data['price'];
        if (productId is! String || productId.isEmpty || title is! String ||
            quantity is! num || !quantity.isFinite || quantity <= 0 ||
            price is! num || !price.isFinite || price < 0) continue;
        items[productId] = CartItem(id: data['id']?.toString(), title: title,
          quantity: quantity.toDouble(), price: price);
      } on FormatException {
        // A damaged local entry does not discard the rest of the cart.
      }
    }
    _snapshots[userId] = Map.of(items);
    return items;
  }

  @override
  Future<void> save(String userId, Map<String, CartItem> items) {
    final snapshot = Map<String, CartItem>.of(items);
    _snapshots[userId] = snapshot;
    final records = snapshot.entries.map((entry) => jsonEncode({
      'productId': entry.key, 'id': entry.value.id, 'title': entry.value.title,
      'quantity': entry.value.quantity, 'price': entry.value.price,
    })).toList();
    final write = _writes.catchError((Object _) {}).then((_) async {
      final saved = await CacheHelper.setStringList(_key(userId), records);
      if (!saved) throw const CartException('Could not save your cart on this device.');
    });
    _writes = write;
    return write;
  }
}
