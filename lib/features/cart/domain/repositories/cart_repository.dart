import 'package:shop_application/features/cart/domain/entities/cart_item.dart';

abstract class CartRepository {
  Map<String, CartItem> load(String userId);
  Future<void> save(String userId, Map<String, CartItem> items);
}

class CartException implements Exception {
  final String message;
  const CartException(this.message);
}
