import 'package:shop_application/core/network/api_result.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/data/models/order/add_order_response_body.dart';
import 'package:shop_application/data/services/order_services.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';

abstract class OrderRepo {
  Future<APIResult<Order>> fetchOrder({
    required String userId,
    required String orderId,
    required String token,
  });

  Future<APIResult<AddOrderResponseBody>> addOrder({
    required Order order,
    required String userId,
    required String token,
  });

  Future<APIResult<List<Order>>> fetchOrders(
    String userId,
    String token,
  );
}

class OrderRepoImpl implements OrderRepo {
  final OrderServices orderServices;

  OrderRepoImpl({required this.orderServices});

  @override
  Future<APIResult<Order>> fetchOrder({
    required String userId,
    required String orderId,
    required String token,
  }) async {
    try {
      final data = await orderServices.fetchSingleOrder(
        userId,
        orderId,
        token,
      );
      return APIResult.success(
        Order.fromJson({
          ...data,
          'id': orderId,
        }),
      );
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<AddOrderResponseBody>> addOrder({
    required Order order,
    required String userId,
    required String token,
  }) async {
    try {
      final data = await orderServices.addOrder(
        order: order,
        userId: userId,
        token: token,
      );
      return APIResult.success(AddOrderResponseBody.fromJson(data));
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<List<Order>>> fetchOrders(
    String userId,
    String token,
  ) async {
    try {
      final data = await orderServices.fetchOrders(userId, token);
      final result = data.entries.map((entry) {
        final orderData = Map<String, dynamic>.from(entry.value as Map);
        return Order.fromJson({
          ...orderData,
          'id': entry.key,
        });
      }).toList()
        ..sort(
          (a, b) => (b.datetime ?? DateTime(0))
              .compareTo(a.datetime ?? DateTime(0)),
        );

      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }
}
