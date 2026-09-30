import 'package:flutter/foundation.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/provider/product.dart';

class RecentlyViewedController with ChangeNotifier {
  static const int maxItems = 10;

  final RecentlyViewedRepository repository;

  RecentlyViewedController({
    required this.repository,
  });

  List<String> _productIds = const [];

  List<String> get productIds => List.unmodifiable(_productIds);

  void load() {
    _productIds = repository.loadProductIds();
    notifyListeners();
  }

  Future<void> record(String productId) async {
    if (productId.trim().isEmpty) {
      return;
    }

    final updated = <String>[
      productId,
      ..._productIds.where((id) => id != productId),
    ];

    _productIds = updated.take(maxItems).toList();
    notifyListeners();
    await repository.saveProductIds(_productIds);
  }

  Future<void> clear() async {
    if (_productIds.isEmpty) {
      return;
    }

    _productIds = const [];
    notifyListeners();
    await repository.clear();
  }

  List<Product> resolveProducts(List<Product> catalog) {
    if (_productIds.isEmpty || catalog.isEmpty) {
      return const [];
    }

    final byId = <String, Product>{};
    for (final product in catalog) {
      final id = product.id ?? product.productId;
      if (id != null) {
        byId[id] = product;
      }
    }

    return _productIds
        .map((id) => byId[id])
        .whereType<Product>()
        .toList();
  }
}
