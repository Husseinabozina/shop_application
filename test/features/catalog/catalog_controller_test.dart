import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';

class _Repository implements ProductRepository {
  List<Product> catalog = [Product(id: 'p1', productId: 'p1', title: 'Lamp', price: 25)];
  final favoriteRequests = <({String id, String user, bool favorite})>[];
  Completer<void>? favoriteCompletion;
  Completer<List<Product>>? fetchCompletion;
  bool failFavorites = false;
  String? addedOwner;

  @override
  Future<List<Product>> fetchProducts({bool? filterByUser, String? userId, String? token}) async {
    if (fetchCompletion != null) return await fetchCompletion!.future;
    return List.of(catalog);
  }

  @override
  Future<void> setFavorite({required String productId, required String token,
    required String userId, required bool isFavorite}) async {
    favoriteRequests.add((id: productId, user: userId, favorite: isFavorite));
    if (favoriteCompletion != null) await favoriteCompletion!.future;
    if (failFavorites) throw const CatalogException('Could not save product. Try again.');
  }

  @override
  Future<Product> updateProduct(Product product, String token) async => product;

  @override
  Future<Product> addProduct(Product product, String token) async {
    addedOwner = product.creatorId;
    return product.copyWith(id: 'created', productId: 'created');
  }

  @override
  Future<void> deleteProduct(String productId, String token) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Unexpected request');
}

void main() {
  late _Repository repository;
  late CatalogController controller;

  setUp(() async {
    repository = _Repository();
    controller = CatalogController(repository: repository, token: 'token', userId: 'owner');
    await controller.fetchProducts();
    await controller.fetchProducts(filterByUser: true);
  });
  tearDown(() => controller.dispose());

  test('optimistic favorites update both lists and block repeated taps', () async {
    final initial = controller.products.single;
    repository.favoriteCompletion = Completer<void>();
    final first = controller.toggleFavorite('p1');
    expect(controller.products.single.isFavorite, isTrue);
    expect(controller.managedProducts.single.isFavorite, isTrue);
    expect(initial.isFavorite, isFalse);
    expect(controller.isFavoritePending('p1'), isTrue);
    expect(await controller.toggleFavorite('p1'), isFalse);
    expect(repository.favoriteRequests, [(id: 'p1', user: 'owner', favorite: true)]);
    repository.favoriteCompletion!.complete();
    expect(await first, isTrue);
    expect(controller.isFavoritePending('p1'), isFalse);
    expect(controller.favoriteError('p1'), isNull);
    expect(controller.favoriteProducts, hasLength(1));
  });

  test('failed save rolls back the flag without discarding an edited listing', () async {
    repository.favoriteCompletion = Completer<void>();
    repository.failFavorites = true;
    final save = controller.toggleFavorite('p1');
    await controller.updateProduct(controller.findById('p1').copyWith(price: 99));
    repository.favoriteCompletion!.complete();
    expect(await save, isFalse);
    expect(controller.products.single.price, 99);
    expect(controller.products.single.isFavorite, isFalse);
    expect(controller.managedProducts.single.isFavorite, isFalse);
    expect(controller.favoriteError('p1'), contains('Try again'));
    repository.failFavorites = false;
    repository.favoriteCompletion = null;
    expect(await controller.toggleFavorite('p1'), isTrue);
    expect(controller.favoriteError('p1'), isNull);
  });

  test('stale refresh cannot undo a completed favorite save', () async {
    repository.fetchCompletion = Completer<List<Product>>();
    final refresh = controller.fetchProducts();
    expect(await controller.toggleFavorite('p1'), isTrue);
    repository.fetchCompletion!.complete(repository.catalog);
    await refresh;
    expect(controller.products.single.isFavorite, isTrue);
  });

  test('refresh during a pending save preserves optimistic state and rolls back on failure', () async {
    repository.favoriteCompletion = Completer<void>();
    repository.failFavorites = true;
    final save = controller.toggleFavorite('p1');
    await controller.fetchProducts();
    expect(controller.products.single.isFavorite, isTrue);
    repository.favoriteCompletion!.complete();
    expect(await save, isFalse);
    expect(controller.products.single.isFavorite, isFalse);
  });

  test('failed favorite after deletion does not bring the product back', () async {
    repository.favoriteCompletion = Completer<void>();
    repository.failFavorites = true;
    final save = controller.toggleFavorite('p1');
    await controller.deleteProduct('p1');
    repository.favoriteCompletion!.complete();
    await save;
    expect(controller.products, isEmpty);
    expect(controller.managedProducts, isEmpty);
  });

  test('new listing ownership comes from the active account', () async {
    await controller.addProduct(Product(title: 'New product', creatorId: 'different-owner'));
    expect(repository.addedOwner, 'owner');
    expect(controller.products.first.id, 'created');
    expect(controller.managedProducts.first.id, 'created');
  });

  test('guest favorites do not make a backend request', () async {
    final guest = CatalogController(repository: repository);
    addTearDown(guest.dispose);
    await guest.fetchProducts();
    expect(await guest.toggleFavorite('p1'), isFalse);
    expect(repository.favoriteRequests, isEmpty);
    expect(guest.favoriteError('p1'), contains('sign in'));
  });

  test('pending request completion after leaving the session is safe', () async {
    final scoped = CatalogController(repository: repository, token: 'token', userId: 'old-owner');
    await scoped.fetchProducts();
    repository.favoriteCompletion = Completer<void>();
    final save = scoped.toggleFavorite('p1');
    var notifications = 0;
    scoped.addListener(() => notifications++);
    scoped.dispose();
    repository.favoriteCompletion!.complete();
    expect(await save, isTrue);
    expect(notifications, 0);
    expect(controller.products.single.isFavorite, isFalse);
  });

  test('callers cannot mutate the controller catalog', () {
    expect(() => controller.products.clear(), throwsUnsupportedError);
    expect(() => controller.managedProducts.clear(), throwsUnsupportedError);
  });
}
