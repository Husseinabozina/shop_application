import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/cart/presentation/controllers/cart_controller.dart';

void main() {
  test('cart refuses quantities above tracked stock', () {
    final cart = CartController();

    expect(
      cart.addItem(
        'product-1',
        10,
        'Product',
        maxQuantity: 2,
      ),
      isTrue,
    );
    expect(
      cart.addItem(
        'product-1',
        10,
        'Product',
        maxQuantity: 2,
      ),
      isTrue,
    );
    expect(
      cart.addItem(
        'product-1',
        10,
        'Product',
        maxQuantity: 2,
      ),
      isFalse,
    );

    expect(cart.items['product-1']?.quantity, 2);
  });

  test('cart keeps legacy untracked products unrestricted', () {
    final cart = CartController();

    for (var index = 0; index < 8; index++) {
      expect(
        cart.addItem(
          'legacy-product',
          10,
          'Legacy product',
        ),
        isTrue,
      );
    }

    expect(cart.items['legacy-product']?.quantity, 8);
  });

  test('zero stock cannot be added', () {
    final cart = CartController();

    expect(
      cart.addItem(
        'sold-out',
        10,
        'Sold out',
        maxQuantity: 0,
      ),
      isFalse,
    );
    expect(cart.items, isEmpty);
  });
}
