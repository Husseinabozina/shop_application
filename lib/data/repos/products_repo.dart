import 'package:shop_application/core/network/api_result.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/data/models/auth/register_response.dart';
import 'package:shop_application/data/models/products/add_products_response_body.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/provider/product.dart';

abstract class ProductsRepo {
  Future<APIResult<List<Product>>> fetchProductsFromJson(
      {bool? filterByUser, String? userId, String? token});
  Future<APIResult<void>> deleteProduct(String productId, String token);
  Future<APIResult<AddProductsResponseBody>> addProduct(
      Product product, String? token);
  Future<APIResult<Product>> updateProduct(Product product, String? token);

  Future<APIResult<Product>> fetchSingleProduct(
      String productId, String? token);
  Future<APIResult<void>> toggleFavoriteStatus({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  });
}

class ProductsRepoImpl extends ProductsRepo {
  final ProductService productService;
  ProductsRepoImpl(this.productService);

  @override
  Future<APIResult<List<Product>>> fetchProductsFromJson({
    bool? filterByUser,
    String? userId,
    String? token,
  }) async {
    try {
      final data = await productService.fetchProducts(
        filterByUser: filterByUser,
        userId: userId,
        token: token,
      );
      final products = data.entries.map((entry) {
        final productId = entry.key;
        final productData = entry.value as Map<String, dynamic>;
        return Product.fromJson(productData, productId);
      }).toList();
      return APIResult.success(products);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<AddProductsResponseBody>> addProduct(
      Product product, String? token) async {
    try {
      final data = await productService.addProduct(product, token);
      return APIResult.success(AddProductsResponseBody.fromJson(data));
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<void>> deleteProduct(String productId, String token) async {
    try {
      await productService.deleteProduct(productId, token);
      return APIResult.success(null);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<Product>> updateProduct(
      Product product, String? token) async {
    try {
      final data = await productService.updateProduct(product, token);
      return APIResult.success(Product.updateFromJson(data));
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<Product>> fetchSingleProduct(
      String productId, String? token) async {
    try {
      final data = await productService.fetchSingleProduct(productId, token);
      return APIResult.success(Product.fromJson(data, productId));
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<void>> toggleFavoriteStatus({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  }) async {
    try {
      await productService.toggleFavoriteStatusOnServer(
        productId: productId,
        token: token,
        userId: userId,
        isFavorite: isFavorite,
      );
      return APIResult.success(null);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }
}
