import 'dart:convert';

import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';

abstract class CheckoutRemoteDataSource {
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  });
}

class FirebaseCheckoutRemoteDataSource implements CheckoutRemoteDataSource {
  final Api api;

  FirebaseCheckoutRemoteDataSource({
    required this.api,
  });

  @override
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  }) async {
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/order/' +
            userId +
            '.json?auth=' +
            accessToken;

    final response = await api.post(
      url: url,
      data: order.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Checkout failed with status ' + response.statusCode.toString(),
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
