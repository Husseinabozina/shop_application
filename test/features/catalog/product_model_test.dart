import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/provider/product.dart';

void main() {
  test('legacy products fall back to the General category', () {
    final product = Product.fromJson(
      {
        'title': 'Legacy product',
        'price': 10,
      },
      'firebase-id',
    );

    expect(product.id, 'firebase-id');
    expect(product.category, 'General');
  });


  test('legacy products remain purchasable when stock is not tracked', () {
    final product = Product.fromJson(
      {
        'title': 'Legacy product',
        'price': 10,
      },
      'legacy-id',
    );

    expect(product.stockQuantity, isNull);
    expect(product.tracksStock, isFalse);
    expect(product.isInStock, isTrue);
    expect(product.stockLabel, 'In stock');
  });

  test('zero tracked stock is sold out', () {
    final product = Product.fromJson(
      {
        'title': 'Sold out product',
        'price': 10,
        'stockQuantity': 0,
      },
      'sold-out-id',
    );

    expect(product.isInStock, isFalse);
    expect(product.isLowStock, isFalse);
    expect(product.stockLabel, 'Sold out');
  });

  test('small tracked quantities expose a low-stock state', () {
    final product = Product.fromJson(
      {
        'title': 'Low stock product',
        'price': 10,
        'stockQuantity': 3,
      },
      'low-stock-id',
    );

    expect(product.isInStock, isTrue);
    expect(product.isLowStock, isTrue);
    expect(product.stockLabel, 'Only 3 left');
  });

  test('product JSON preserves category and creator ownership', () {
    final product = Product(
      id: 'product-1',
      productId: 'product-1',
      title: 'Headphones',
      description: 'Wireless headphones',
      imageUrl: 'https://example.com/image.jpg',
      price: 50,
      category: 'Electronics',
      creatorId: 'user-1',
      stockQuantity: 12,
    );

    final json = product.toJson();

    expect(json['category'], 'Electronics');
    expect(json['creatorId'], 'user-1');
    expect(json['price'], 50);
    expect(json['stockQuantity'], 12);
  });
}
