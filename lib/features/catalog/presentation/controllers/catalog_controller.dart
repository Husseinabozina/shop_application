import 'package:flutter/foundation.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';

class CatalogController with ChangeNotifier {
  final ProductRepository repository;
  final String? token;
  final String? userId;

  CatalogController({required this.repository, this.token, this.userId});

  List<Product> _products = [];
  List<Product> _managedProducts = [];
  Product? _updatedProduct;
  bool _disposed = false;
  int _favoriteRevision = 0;
  final Map<String, int> _favoriteVersions = {};
  final Map<String, bool> _pendingFavorites = {};
  final Map<String, String> _favoriteErrors = {};

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get managedProducts => List.unmodifiable(_managedProducts);
  Product? get updatedProduct => _updatedProduct;
  List<Product> get favoriteProducts => _products.where((p) => p.isFavorite).toList();

  List<String> get categories {
    return _products.map((p) => p.category.trim())
        .where((category) => category.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  String? fetchProductsErrorMessage;
  String? deleteProductSuccessMessage;
  String? deleteProductErrorMessage;
  String? updateProductErrorMessage;

  bool isFavoritePending(String id) => _pendingFavorites.containsKey(id);
  String? favoriteError(String id) => _favoriteErrors[id];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> fetchProducts({bool? filterByUser}) async {
    final revision = _favoriteRevision;
    try {
      final loaded = await repository.fetchProducts(
        filterByUser: filterByUser, userId: userId, token: token,
      );
      if (_disposed) return;
      final products = loaded.map((product) {
        final id = product.productId ?? product.id;
        if (id == null) return product;
        // A refresh started before a favorite action must not undo that action.
        if (_pendingFavorites.containsKey(id)) {
          return product.copyWith(isFavorite: _pendingFavorites[id]);
        }
        if ((_favoriteVersions[id] ?? 0) > revision) {
          final current = _find(id);
          if (current != null) return product.copyWith(isFavorite: current.isFavorite);
        }
        return product;
      }).toList();
      if (filterByUser == true) {
        _managedProducts = products;
      } else {
        _products = products;
      }
      fetchProductsErrorMessage = null;
    } on CatalogException catch (error) {
      if (_disposed) return;
      fetchProductsErrorMessage = error.message;
    }
    _notify();
  }

  Product? _find(String id) {
    for (final product in [..._managedProducts, ..._products]) {
      if (product.id == id || product.productId == id) return product;
    }
    return null;
  }

  Product findById(String id) {
    final product = _find(id);
    if (product == null) throw StateError('Product $id is unavailable.');
    return product;
  }

  void _replaceFavorite(String id, bool favorite) {
    Product update(Product product) => product.id == id || product.productId == id
        ? product.copyWith(isFavorite: favorite) : product;
    _products = _products.map(update).toList();
    _managedProducts = _managedProducts.map(update).toList();
  }

  Future<bool> toggleFavorite(String id) async {
    if (_disposed || isFavoritePending(id)) return false;
    final product = _find(id);
    final accessToken = token;
    final activeUserId = userId;
    if (product == null || accessToken == null || accessToken.isEmpty ||
        activeUserId == null || activeUserId.isEmpty) {
      _favoriteErrors[id] = 'Please sign in again to save products.';
      _notify();
      return false;
    }
    final oldStatus = product.isFavorite;
    final nextStatus = !oldStatus;
    _favoriteErrors.remove(id);
    _pendingFavorites[id] = nextStatus;
    _favoriteVersions[id] = ++_favoriteRevision;
    _replaceFavorite(id, nextStatus);
    _notify();
    var succeeded = false;
    try {
      await repository.setFavorite(
        productId: id, token: accessToken, userId: activeUserId,
        isFavorite: nextStatus,
      );
      succeeded = true;
    } on CatalogException catch (error) {
      if (!_disposed) {
        // Replace only the favorite flag, preserving concurrent product edits.
        _replaceFavorite(id, oldStatus);
        _favoriteErrors[id] = error.message;
      }
    } finally {
      if (!_disposed) {
        _pendingFavorites.remove(id);
        _favoriteVersions[id] = ++_favoriteRevision;
        _notify();
      }
    }
    return succeeded;
  }

  Future<void> deleteProduct(String productId) async {
    final accessToken = token;
    if (accessToken == null || accessToken.isEmpty) {
      deleteProductErrorMessage = 'Please sign in again.';
      _notify();
      return;
    }
    try {
      await repository.deleteProduct(productId, accessToken);
      if (_disposed) return;
      deleteProductSuccessMessage = AppStrings.deleteProductSuccessMessage;
      _products.removeWhere((p) => p.id == productId || p.productId == productId);
      _managedProducts.removeWhere((p) => p.id == productId || p.productId == productId);
      deleteProductErrorMessage = null;
    } on CatalogException catch (error) {
      if (_disposed) return;
      deleteProductErrorMessage = error.message;
    }
    _notify();
  }

  Future<void> updateProduct(Product product) async {
    final accessToken = token;
    if (accessToken == null || accessToken.isEmpty) {
      updateProductErrorMessage = 'Please sign in again.';
      _notify();
      return;
    }
    try {
      var updated = await repository.updateProduct(product, accessToken);
      if (_disposed) return;
      final id = product.productId ?? product.id;
      final current = id == null ? null : _find(id);
      if (current != null) updated = updated.copyWith(isFavorite: current.isFavorite);
      _updatedProduct = updated;
      Product replace(Product existing) => existing.id == id || existing.productId == id
          ? updated : existing;
      _products = _products.map(replace).toList();
      _managedProducts = _managedProducts.map(replace).toList();
      updateProductErrorMessage = null;
    } on CatalogException catch (error) {
      if (_disposed) return;
      updateProductErrorMessage = error.message;
    }
    _notify();
  }

  Future<void> addProduct(Product product) async {
    final accessToken = token;
    final activeUserId = userId;
    if (accessToken == null || accessToken.isEmpty ||
        activeUserId == null || activeUserId.isEmpty) {
      updateProductErrorMessage = 'Please sign in again.';
      _notify();
      return;
    }
    try {
      final created = await repository.addProduct(
        product.copyWith(creatorId: activeUserId), accessToken,
      );
      if (_disposed) return;
      _products.insert(0, created);
      _managedProducts.insert(0, created);
      updateProductErrorMessage = null;
    } on CatalogException catch (error) {
      if (_disposed) return;
      updateProductErrorMessage = error.message;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
