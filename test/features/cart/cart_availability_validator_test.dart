import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/features/cart/domain/services/cart_availability_validator.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';

void main() {
  const validator = CartAvailabilityValidator();

  CartModel cartItem({
    required String title,
    required double quantity,
  }) {
    return CartModel(
      id: 'cart-id',
      title: title,
      quantity: quantity,
      price: 10,
    );
  }

  test('untracked stock does not block checkout', () {
    final issues = validator.validate(
      cartItems: {
        'product-1': cartItem(
          title: 'Legacy product',
          quantity: 20,
        ),
      },
      products: [
        Product(
          id: 'product-1',
          title: 'Legacy product',
          price: 10,
        ),
      ],
    );

    expect(issues, isEmpty);
  });

  test('missing catalog product blocks checkout', () {
    final issues = validator.validate(
      cartItems: {
        'missing': cartItem(
          title: 'Removed product',
          quantity: 1,
        ),
      },
      products: const [],
    );

    expect(issues.single.type, CartAvailabilityIssueType.unavailable);
  });

  test('sold out product blocks checkout', () {
    final issues = validator.validate(
      cartItems: {
        'product-1': cartItem(
          title: 'Product',
          quantity: 1,
        ),
      },
      products: [
        Product(
          id: 'product-1',
          title: 'Product',
          stockQuantity: 0,
        ),
      ],
    );

    expect(issues.single.type, CartAvailabilityIssueType.soldOut);
  });

  test('quantity above current stock blocks checkout', () {
    final issues = validator.validate(
      cartItems: {
        'product-1': cartItem(
          title: 'Product',
          quantity: 4,
        ),
      },
      products: [
        Product(
          id: 'product-1',
          title: 'Product',
          stockQuantity: 2,
        ),
      ],
    );

    expect(
      issues.single.type,
      CartAvailabilityIssueType.insufficientStock,
    );
    expect(issues.single.availableQuantity, 2);
  });

  test('quantity within stock passes checkout preflight', () {
    final issues = validator.validate(
      cartItems: {
        'product-1': cartItem(
          title: 'Product',
          quantity: 2,
        ),
      },
      products: [
        Product(
          id: 'product-1',
          title: 'Product',
          stockQuantity: 2,
        ),
      ],
    );

    expect(issues, isEmpty);
  });
}
