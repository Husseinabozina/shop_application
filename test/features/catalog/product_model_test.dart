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
    );

    final json = product.toJson();

    expect(json['category'], 'Electronics');
    expect(json['creatorId'], 'user-1');
    expect(json['price'], 50);
  });
}
