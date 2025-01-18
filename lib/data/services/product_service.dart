import 'dart:convert';

import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/provider/product.dart';

import '../../core/network/error_handler.dart';

abstract class ProductService {
  Future<Map<String, dynamic>> fetchProducts(
      {bool? filterByUser, String? userId, String? token});
  Future<Map<String, dynamic>> addProduct(Product product, String? token);
  Future<void> deleteProduct(String productId, String token);
  Future<Map<String, dynamic>> updateProduct(Product product, String? token);
  Future<Map<String, dynamic>> fetchSingleProduct(
      String productId, String? token);
  Future<void> toggleFavoriteStatusOnServer({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  });
}

class ProductServiceImpl extends ProductService {
  Api api;

  ProductServiceImpl({
    required this.api,
  });

  @override
  Future<Map<String, dynamic>> addProduct(
      Product product, String? token) async {
    final url =
        "https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token";
    try {
      final response = await api.post(url: url, data: product.toJson());
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> deleteProduct(String productId, String? token) async {
    final url =
        "https://shopapp-29118-default-rtdb.firebaseio.com/products/${productId}.json?auth=$token";
    try {
      final response = await api.delete(url: url);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProducts(
      {bool? filterByUser, String? userId, String? token}) async {
    final String filterString =
        filterByUser == true ? '&orderBy="creatorId"&equalTo="$userId"' : '';
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token$filterString';
    try {
      final response = await api.get(url: url);
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateProduct(
      Product product, String? token) async {
    final url =
        "https://shopapp-29118-default-rtdb.firebaseio.com/products/${product.productId}.json?auth=$token";
    try {
      final response = await api.patch(url: url, data: product.toJson());
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchSingleProduct(
      String productId, String? token) async {
    final url =
        "https://shopapp-29118-default-rtdb.firebaseio.com/products/${productId}.json?auth=$token";
    try {
      final response = await api.get(url: url);
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<void> toggleFavoriteStatusOnServer({
    required String productId,
    required String token,
    required String userId,
    required bool? isFavorite,
  }) async {
    final url =
        "https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId/$productId.json?auth=$token";
    try {
      await api.put(url: url, data: json.encode(isFavorite));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
