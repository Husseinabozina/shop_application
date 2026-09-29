import 'dart:convert';

import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/provider/order.dart';

abstract class OrderServices {
  Future<Map<String, dynamic>> fetchSingleOrder(
    String orderId,
    String? token,
  );

  Future<Map<String, dynamic>> fetchOrders(
    String userId,
    String token,
  );

  Future<Map<String, dynamic>> addOrder({
    required Order order,
    String? userId,
    String? token,
  });
}

class OrderServicesImpl extends OrderServices {
  final Api api;

  OrderServicesImpl(this.api);

  @override
  Future<Map<String, dynamic>> fetchSingleOrder(
    String orderId,
    String? token,
  ) async {
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/order/$orderId.json?auth=$token';

    try {
      final response = await api.get(url: url);
      return _decodeMap(response.body);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> addOrder({
    required Order order,
    String? userId,
    String? token,
  }) async {
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token';

    try {
      final response = await api.post(url: url, data: order.toJson());
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
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token';

    try {
      final response = await api.get(url: url);
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
}
