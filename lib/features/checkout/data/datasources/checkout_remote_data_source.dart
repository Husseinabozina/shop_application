import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';

abstract class CheckoutRemoteDataSource {
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  });
}

class FirebaseCheckoutRemoteDataSource implements CheckoutRemoteDataSource {
  final FirebaseRestClient database;

  FirebaseCheckoutRemoteDataSource({
    required this.database,
  });

  @override
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  }) async {
    final response = await database.post(
      path: 'order/$userId',
      authToken: accessToken,
      data: order.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Checkout failed with status ${response.statusCode}.',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final orderId = decoded['name']?.toString();

    if (orderId == null || orderId.isEmpty) {
      throw Exception('Checkout completed without an order id.');
    }

    return CheckoutResult(orderId: orderId);
  }
}
