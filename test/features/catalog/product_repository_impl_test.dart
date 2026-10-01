import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/features/catalog/data/datasources/product_remote_data_source.dart';
import 'package:shop_application/features/catalog/data/repositories/product_repository_impl.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';

import '../../support/memory_shop_api.dart';

void main() {
  late MemoryShopApi api;
  late ProductRepository repository;

  setUp(() {
    api = MemoryShopApi();
    repository = ProductRepositoryImpl(FirebaseProductRemoteDataSource(
      database: FirebaseRestClientImpl(api: api),
    ));
    api.products['record-key'] = {
      'id': 'legacy-wrong-id', 'title': 'Lamp', 'price': 25,
      'creatorId': 'owner', 'imagurl': 'https://example.com/lamp.jpg',
      'isFavorite': true,
    };
    api.products['other-product'] = {'title': 'Bag', 'price': 50, 'creatorId': 'other'};
  });

  test('maps legacy data and uses the record key as the canonical ID', () async {
    final products = await repository.fetchProducts();
    final lamp = products.first;
    expect(lamp.id, 'record-key');
    expect(lamp.productId, 'record-key');
    expect(lamp.category, 'General');
    expect(lamp.imageUrls, ['https://example.com/lamp.jpg']);
    expect(lamp.isFavorite, isFalse);
    expect(lamp.isInStock, isTrue);
  });

  test('seller queries stay scoped and favorites come from the private collection', () async {
    api.favorites['record-key'] = true;
    final owned = await repository.fetchProducts(filterByUser: true, userId: 'owner', token: 'token');
    expect(owned, hasLength(1));
    expect(owned.single.creatorId, 'owner');
    expect(owned.single.isFavorite, isTrue);
    await expectLater(repository.fetchProducts(filterByUser: true),
      throwsA(isA<CatalogException>().having((e) => e.message, 'message', contains('sign in'))));
  });

  test('create, edit, and delete operate on domain products and preserve private favorites', () async {
    final created = await repository.addProduct(Product(
      title: 'Mug', price: 10, creatorId: 'owner', stockQuantity: 3,
      isFavorite: true,
    ), 'token');
    expect(created.id, 'created-product-1');
    expect(api.products[created.id]['isFavorite'], isNull);
    final updated = await repository.updateProduct(created.copyWith(price: 12), 'token');
    expect(updated.price, 12);
    expect(updated.isFavorite, isTrue);
    expect(api.products[created.id]['creatorId'], 'owner');
    expect(api.products[created.id]['stockQuantity'], 3);
    expect(api.products[created.id]['isFavorite'], isNull);
    final single = await repository.fetchSingleProduct(created.id!, 'token');
    expect(single.price, 12);
    await repository.deleteProduct(created.id!, 'token');
    expect(api.products.containsKey(created.id), isFalse);
    await expectLater(repository.fetchSingleProduct(created.id!, 'token'), throwsA(isA<CatalogException>()));
  });

  test('favorite failures cross the repository as domain errors and can be retried', () async {
    api.failFavoriteWrites = true;
    await expectLater(repository.setFavorite(productId: 'record-key', token: 'token',
      userId: 'owner', isFavorite: true), throwsA(isA<CatalogException>().having(
        (e) => e.message, 'message', 'Could not update favorite status.')));
    expect(api.favorites, isEmpty);
    api.failFavoriteWrites = false;
    await repository.setFavorite(productId: 'record-key', token: 'token', userId: 'owner', isFavorite: true);
    expect(api.favorites['record-key'], isTrue);
  });
}
