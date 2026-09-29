import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';

abstract class OrderServices {
  Future<Map<String, dynamic>> fetchSingleOrder(
    String userId,
    String orderId,
    String token,
  );

  Future<Map<String, dynamic>> fetchOrders(
    String userId,
    String token,
  );

  Future<Map<String, dynamic>> addOrder({
    required Order order,
    required String userId,
    required String token,
  });
}

class OrderServicesImpl extends OrderServices {
  final FirebaseRestClient database;

  OrderServicesImpl(this.database);

  @override
  Future<Map<String, dynamic>> fetchSingleOrder(
    String userId,
    String orderId,
    String token,
  ) async {
    try {
      final response = await database.get(
        path: 'order/$userId/$orderId',
        authToken: token,
      );
      _ensureSuccess(response.statusCode, 'Could not load order.');
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> addOrder({
    required Order order,
    required String userId,
    required String token,
  }) async {
    try {
      final response = await database.post(
        path: 'order/$userId',
        authToken: token,
        data: order.toJson(),
      );
      _ensureSuccess(response.statusCode, 'Could not create order.');
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchOrders(
    String userId,
    String token,
  ) async {
    try {
      final response = await database.get(
        path: 'order/$userId',
        authToken: token,
      );
      _ensureSuccess(response.statusCode, 'Could not load orders.');
      return _decodeMap(response.body);
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
