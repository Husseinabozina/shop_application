import 'package:shop_application/core/network/api_result.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/data/models/order/add_order_response_body.dart';
import 'package:shop_application/data/services/order_services.dart';
import 'package:shop_application/provider/order.dart';

abstract class OrderRepo {
  Future<APIResult<Order>> fetchOrder(String productId, String? token);
  Future<APIResult<AddOrderResponseBody>> addOrder(
      {required Order order, String? userId, String? token});
  Future<APIResult<List<Order>>> fetchOrders(String token);
}

class OrderRepoImpl implements OrderRepo {
  final OrderServices orderServices;

  OrderRepoImpl({required this.orderServices});

  @override
  Future<APIResult<Order>> fetchOrder(String productId, String? token) async {
    try {
      final data = await orderServices.fetchSingleOrder(productId, token);
      final result = Order.fromJson(data);
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<AddOrderResponseBody>> addOrder(
      {required Order order, String? userId, String? token}) async {
    try {
      final data = await orderServices.addOrder(
          order: order, userId: userId, token: token);
      final result = AddOrderResponseBody.fromJson(data);
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  Future<APIResult<List<Order>>> fetchOrders(String token) async {
    try {
      final data = await orderServices.fetchOrders(token);
      final result = data.entries.map((entry) {
        final orderId = entry.key;
        final orderData = entry.value as Map<String, dynamic>;
        return Order.fromJson(orderData);
      }).toList();
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }
}
