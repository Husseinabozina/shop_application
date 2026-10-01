import 'package:shop_application/features/catalog/domain/entities/product.dart';

/// Application-facing catalog operations. Backend formats stay in the data layer.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts({
    bool? filterByUser,
    String? userId,
    String? token,
  });

  Future<Product> addProduct(Product product, String token);
  Future<Product> updateProduct(Product product, String token);
  Future<void> deleteProduct(String productId, String token);
  Future<Product> fetchSingleProduct(String productId, String? token);

  Future<void> setFavorite({
    required String productId,
    required String token,
    required String userId,
    required bool isFavorite,
  });
}

class CatalogException implements Exception {
  final String message;

  const CatalogException(this.message);

  @override
  String toString() => message;
}
