import 'package:flutter/foundation.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/provider/product.dart';

class RecentlyViewedController with ChangeNotifier {
  static const int maxItems = 10;

  final RecentlyViewedRepository repository;
  final String? userId;

  RecentlyViewedController({
    required this.repository,
    this.userId,
  });

  List<String> _productIds = const [];

  List<String> get productIds => List.unmodifiable(_productIds);

  void load() {
    final scope = _scope;
    _productIds =
        scope == null ? const [] : repository.loadProductIds(scope);
  }

  Future<void> record(String productId) async {
    final scope = _scope;
    if (scope == null || productId.trim().isEmpty) {
      return;
    }

    final updated = <String>[
      productId,
      ..._productIds.where((id) => id != productId),
    ];

    _productIds = updated.take(maxItems).toList();
    notifyListeners();
    await repository.saveProductIds(
      scope,
      _productIds,
    );
  }

  Future<void> clear() async {
    final scope = _scope;
    if (scope == null || _productIds.isEmpty) {
      return;
    }

    _productIds = const [];
    notifyListeners();
    await repository.clear(scope);
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

  String? get _scope {
    final value = userId?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
