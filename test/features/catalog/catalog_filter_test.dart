import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/catalog/domain/entities/catalog_filter.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';

void main() {
  test('empty filter matches every product', () {
    const filter = CatalogFilter.empty;

    expect(
      filter.matches(
        Product(
          price: 10,
          stockQuantity: 0,
        ),
      ),
      isTrue,
    );
  });

  test('price range is inclusive', () {
    const filter = CatalogFilter(
      minPrice: 10,
      maxPrice: 20,
    );

    expect(filter.matches(Product(price: 10)), isTrue);
    expect(filter.matches(Product(price: 15)), isTrue);
    expect(filter.matches(Product(price: 20)), isTrue);
    expect(filter.matches(Product(price: 9)), isFalse);
    expect(filter.matches(Product(price: 21)), isFalse);
  });

  test('in-stock filter hides sold-out tracked products', () {
    const filter = CatalogFilter(
      inStockOnly: true,
    );

    expect(
      filter.matches(
        Product(
          price: 10,
          stockQuantity: 0,
        ),
      ),
      isFalse,
    );
    expect(
      filter.matches(
        Product(
          price: 10,
          stockQuantity: 3,
        ),
      ),
      isTrue,
    );
    expect(
      filter.matches(
        Product(price: 10),
      ),
      isTrue,
    );
  });

  test('active filter count groups the price range as one filter', () {
    const filter = CatalogFilter(
      minPrice: 10,
      maxPrice: 20,
      inStockOnly: true,
    );

    expect(filter.activeCount, 2);
    expect(filter.isActive, isTrue);
  });
}
