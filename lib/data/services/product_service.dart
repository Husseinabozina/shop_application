import 'dart:convert';

import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/provider/product.dart';

import '../../core/network/error_handler.dart';

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
  final Api api;

  ProductServiceImpl({
    required this.api,
  });

  @override
  Future<Map<String, dynamic>> addProduct(
    Product product,
    String? token,
  ) async {
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token';

    try {
      final response = await api.post(
        url: url,
        data: product.toJson(),
      );
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
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products/$productId.json?auth=$token';

    try {
      await api.delete(url: url);
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
    final filterString = filterByUser == true
        ? '&orderBy="creatorId"&equalTo="$userId"'
        : '';
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token$filterString';

    try {
      final response = await api.get(url: url);
      final products = _decodeMap(response.body);

      if (products.isEmpty || userId == null || token == null) {
        return products;
      }

      final favoriteResponse = await api.get(
        url:
            'https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId.json?auth=$token',
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
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products/' +
            (product.productId ?? product.id ?? '') +
            '.json?auth=$token';

    try {
      final response = await api.patch(
        url: url,
        data: product.toJson(),
      );
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
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products/$productId.json?auth=$token';

    try {
      final response = await api.get(url: url);
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
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId/$productId.json?auth=$token';

    try {
      await api.put(
        url: url,
        data: isFavorite ?? false,
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
}
