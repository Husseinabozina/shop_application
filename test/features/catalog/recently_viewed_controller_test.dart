import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/provider/product.dart';

class _FakeRecentlyViewedRepository
    implements RecentlyViewedRepository {
  final Map<String, List<String>> values = {};

  @override
  List<String> loadProductIds(String scope) {
    return List<String>.from(values[scope] ?? const []);
  }

  @override
  Future<void> saveProductIds(
    String scope,
    List<String> productIds,
  ) async {
    values[scope] = List<String>.from(productIds);
  }

  @override
  Future<void> clear(String scope) async {
    values.remove(scope);
  }
}

void main() {
  late _FakeRecentlyViewedRepository repository;

  setUp(() {
    repository = _FakeRecentlyViewedRepository();
  });

  test('most recent product moves to the front without duplicates',
      () async {
    final controller = RecentlyViewedController(
      repository: repository,
      userId: 'user-1',
    )..load();

    await controller.record('product-1');
    await controller.record('product-2');
    await controller.record('product-1');

    expect(
      controller.productIds,
      ['product-1', 'product-2'],
    );
    expect(
      repository.values['user-1'],
      ['product-1', 'product-2'],
    );
  });

  test('recent history is capped at ten products', () async {
    final controller = RecentlyViewedController(
      repository: repository,
      userId: 'user-1',
    )..load();

    for (var index = 0; index < 12; index++) {
      await controller.record('product-$index');
    }

    expect(controller.productIds.length, 10);
    expect(controller.productIds.first, 'product-11');
    expect(controller.productIds.last, 'product-2');
  });

  test('recent history stays isolated between user scopes', () async {
    repository.values['user-a'] = ['product-a'];
    repository.values['user-b'] = ['product-b'];

    final userA = RecentlyViewedController(
      repository: repository,
      userId: 'user-a',
    )..load();
    final userB = RecentlyViewedController(
      repository: repository,
      userId: 'user-b',
    )..load();

    expect(userA.productIds, ['product-a']);
    expect(userB.productIds, ['product-b']);
  });

  test('resolving products keeps recent order and skips missing ids', () {
    repository.values['user-1'] = [
      'product-2',
      'missing',
      'product-1',
    ];

    final controller = RecentlyViewedController(
      repository: repository,
      userId: 'user-1',
    )..load();

    final products = controller.resolveProducts([
      Product(
        id: 'product-1',
        title: 'One',
      ),
      Product(
        id: 'product-2',
        title: 'Two',
      ),
    ]);

    expect(
      products.map((product) => product.id).toList(),
      ['product-2', 'product-1'],
    );
  });
}
