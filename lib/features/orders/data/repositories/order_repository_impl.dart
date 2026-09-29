import 'package:shop_application/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<Order>> fetchOrders({
    required String userId,
    required String accessToken,
  }) async {
    final data = await remoteDataSource.fetchOrders(
      userId: userId,
      accessToken: accessToken,
    );

    final orders = data.entries.map((entry) {
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

    return orders;
  }

  @override
  Future<Order> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  }) async {
    final data = await remoteDataSource.fetchOrder(
      userId: userId,
      orderId: orderId,
      accessToken: accessToken,
    );

    return Order.fromJson({
      ...data,
      'id': orderId,
    });
  }
}
