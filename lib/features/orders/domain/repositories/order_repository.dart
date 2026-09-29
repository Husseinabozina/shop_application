import 'package:shop_application/features/orders/domain/entities/order.dart';

abstract class OrderRepository {
  Future<List<Order>> fetchOrders({
    required String userId,
    required String accessToken,
  });

  Future<Order> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  });
}
