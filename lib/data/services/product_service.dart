import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/provider/product.dart';

abstract class ProductService {
  Future<Map<String, dynamic>> fetchProducts({
    bool? filterByUser,
    String? userId,
    String? token,
  });

  Future<Map<String, dynamic>> addProduct(Product product, String? token);
  Future<void> deleteProduct(String productId, String token);
  Future<Map<String, dynamic>> updateProduct(Product product, String? token);

  Future<Map<String, dynamic>> fetchSingleProduct(
    String productId,
    String? token,
  );

  Future<void> toggleFavoriteStatusOnServer({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  });
}

class ProductServiceImpl extends ProductService {
  final FirebaseRestClient database;

  ProductServiceImpl({
    required this.database,
  });

  @override
  Future<Map<String, dynamic>> addProduct(
    Product product,
    String? token,
  ) async {
    try {
      final response = await database.post(
        path: 'products',
        authToken: token,
        data: product.toJson(),
      );
      _ensureSuccess(response.statusCode, 'Could not add product.');
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> deleteProduct(
    String productId,
    String? token,
  ) async {
    try {
      final response = await database.delete(
        path: 'products/$productId',
        authToken: token,
      );
      _ensureSuccess(response.statusCode, 'Could not delete product.');
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProducts({
    bool? filterByUser,
    String? userId,
    String? token,
  }) async {
    final query = filterByUser == true
        ? <String, dynamic>{
            'orderBy': '"creatorId"',
            'equalTo': '"$userId"',
          }
        : null;

    try {
      final response = await database.get(
        path: 'products',
        authToken: token,
        query: query,
      );
      _ensureSuccess(response.statusCode, 'Could not load products.');

      final products = _decodeMap(response.body);

      if (products.isEmpty || userId == null || token == null) {
        return products;
      }

      final favoriteResponse = await database.get(
        path: 'userfavorite/$userId',
        authToken: token,
      );
      _ensureSuccess(
        favoriteResponse.statusCode,
        'Could not load favorites.',
      );
      final favorites = _decodeMap(favoriteResponse.body);

      for (final entry in products.entries) {
        final productData = entry.value;
        if (productData is Map<String, dynamic>) {
          productData['isFavorite'] = favorites[entry.key] == true;
        }
      }

      return products;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateProduct(
    Product product,
    String? token,
  ) async {
    final productId = product.productId ?? product.id ?? '';
    if (productId.isEmpty) {
      throw ExceptionHandler.handle('Product id is missing.');
    }

    try {
      final response = await database.patch(
        path: 'products/$productId',
        authToken: token,
        data: product.toJson(),
      );
      _ensureSuccess(response.statusCode, 'Could not update product.');
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchSingleProduct(
    String productId,
    String? token,
  ) async {
    try {
      final response = await database.get(
        path: 'products/$productId',
        authToken: token,
      );
      _ensureSuccess(response.statusCode, 'Could not load product.');
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> toggleFavoriteStatusOnServer({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  }) async {
    try {
      final response = await database.put(
        path: 'userfavorite/$userId/$productId',
        authToken: token,
        data: isFavorite ?? false,
      );
      _ensureSuccess(
        response.statusCode,
        'Could not update favorite status.',
      );
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = json.decode(body);
    if (decoded == null) {
      return <String, dynamic>{};
    }
    return decoded as Map<String, dynamic>;
  }

  void _ensureSuccess(int statusCode, String message) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('$message Status $statusCode.');
    }
  }
}
