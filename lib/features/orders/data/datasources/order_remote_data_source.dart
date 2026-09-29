import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';

abstract class OrderRemoteDataSource {
  Future<Map<String, dynamic>> fetchOrders({
    required String userId,
    required String accessToken,
  });

  Future<Map<String, dynamic>> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  });
}

class FirebaseOrderRemoteDataSource implements OrderRemoteDataSource {
  final FirebaseRestClient database;

  FirebaseOrderRemoteDataSource({
    required this.database,
  });

  @override
  Future<Map<String, dynamic>> fetchOrders({
    required String userId,
    required String accessToken,
  }) async {
    final response = await database.get(
      path: 'order/$userId',
      authToken: accessToken,
    );

    _ensureSuccess(response.statusCode, 'Could not load orders.');
    return _decodeMap(response.body);
  }

  @override
  Future<Map<String, dynamic>> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  }) async {
    final response = await database.get(
      path: 'order/$userId/$orderId',
      authToken: accessToken,
    );

    _ensureSuccess(response.statusCode, 'Could not load order.');
    return _decodeMap(response.body);
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = json.decode(body);
    if (decoded == null) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  void _ensureSuccess(int statusCode, String message) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('$message Status $statusCode.');
    }
  }
}
