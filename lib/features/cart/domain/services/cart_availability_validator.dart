import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/provider/product.dart';

enum CartAvailabilityIssueType {
  unavailable,
  soldOut,
  insufficientStock,
}

class CartAvailabilityIssue {
  final String productId;
  final String title;
  final CartAvailabilityIssueType type;
  final double requestedQuantity;
  final int? availableQuantity;

  const CartAvailabilityIssue({
    required this.productId,
    required this.title,
    required this.type,
    required this.requestedQuantity,
    this.availableQuantity,
  });

  String get message {
    switch (type) {
      case CartAvailabilityIssueType.unavailable:
        return '$title is no longer available.';
      case CartAvailabilityIssueType.soldOut:
        return '$title is sold out.';
      case CartAvailabilityIssueType.insufficientStock:
        return 'Only $availableQuantity of $title are available.';
    }
  }
}

class CartAvailabilityValidator {
  const CartAvailabilityValidator();

  List<CartAvailabilityIssue> validate({
    required Map<String, CartModel> cartItems,
    required List<Product> products,
  }) {
    if (cartItems.isEmpty) {
      return const [];
    }

    final byId = <String, Product>{};
    for (final product in products) {
      final id = product.id ?? product.productId;
      if (id != null) {
        byId[id] = product;
      }
    }

    final issues = <CartAvailabilityIssue>[];

    for (final entry in cartItems.entries) {
      final productId = entry.key;
      final cartItem = entry.value;
      final product = byId[productId];
      final title = cartItem.title ?? product?.title ?? 'Product';
      final requestedQuantity = cartItem.quantity ?? 0;

      if (product == null) {
        issues.add(
          CartAvailabilityIssue(
            productId: productId,
            title: title,
            type: CartAvailabilityIssueType.unavailable,
            requestedQuantity: requestedQuantity,
          ),
        );
        continue;
      }

      final stock = product.stockQuantity;
      if (stock == null) {
        continue;
      }

      if (stock <= 0) {
        issues.add(
          CartAvailabilityIssue(
            productId: productId,
            title: title,
            type: CartAvailabilityIssueType.soldOut,
            requestedQuantity: requestedQuantity,
            availableQuantity: 0,
          ),
        );
        continue;
      }

      if (requestedQuantity > stock) {
        issues.add(
          CartAvailabilityIssue(
            productId: productId,
            title: title,
            type: CartAvailabilityIssueType.insufficientStock,
            requestedQuantity: requestedQuantity,
            availableQuantity: stock,
          ),
        );
      }
    }

    return issues;
  }
}
