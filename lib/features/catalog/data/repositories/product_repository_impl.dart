import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/features/catalog/data/datasources/product_remote_data_source.dart';
import 'package:shop_application/features/catalog/data/models/product_mapper.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      if (error is CatalogException) rethrow;
      throw CatalogException(ExceptionHandler.handle(error).message);
    }
  }

  @override
  Future<List<Product>> fetchProducts({
    bool? filterByUser,
    String? userId,
    String? token,
  }) => _run(() async {
    final data = await remoteDataSource.fetchProducts(
      filterByUser: filterByUser,
      userId: userId,
      token: token,
    );
    return data.entries.map((entry) {
      return ProductMapper.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
        entry.key,
      );
    }).toList();
  });

  @override
  Future<Product> addProduct(Product product, String token) => _run(() async {
    final response = await remoteDataSource.addProduct(product, token);
    final id = response['name'];
    if (id is! String || id.isEmpty) {
      throw const CatalogException(
        'Could not confirm the saved product. '
        'Refresh your products before trying again.',
      );
    }
    return product.copyWith(id: id, productId: id);
  });

  @override
  Future<Product> updateProduct(Product product, String token) => _run(() async {
    final id = product.productId ?? product.id;
    if (id == null || id.isEmpty) {
      throw const CatalogException('Product id is missing.');
    }
    final data = await remoteDataSource.updateProduct(product, token);
    return ProductMapper.fromJson(data, id).copyWith(
      isFavorite: product.isFavorite,
    );
  });

  @override
  Future<void> deleteProduct(String productId, String token) =>
      _run(() => remoteDataSource.deleteProduct(productId, token));

  @override
  Future<Product> fetchSingleProduct(String productId, String? token) =>
      _run(() async {
        final data = await remoteDataSource.fetchSingleProduct(productId, token);
        if (data.isEmpty) {
          throw const CatalogException('This product is no longer available.');
        }
        // A shared record cannot supply a user's private favorite state.
        return ProductMapper.fromJson(data, productId).copyWith(isFavorite: false);
      });

  @override
  Future<void> setFavorite({
    required String productId,
    required String token,
    required String userId,
    required bool isFavorite,
  }) => _run(
    () => remoteDataSource.toggleFavoriteStatusOnServer(
      productId: productId,
      token: token,
      userId: userId,
      isFavorite: isFavorite,
    ),
  );
}
