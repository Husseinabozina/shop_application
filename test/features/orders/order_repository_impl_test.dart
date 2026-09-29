import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shop_application/features/orders/data/repositories/order_repository_impl.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';

class _FakeOrderRemoteDataSource implements OrderRemoteDataSource {
  @override
  Future<Map<String, dynamic>> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  }) async {
    return {
      'datetime': '2026-09-30T10:00:00.000',
      'amount': 100,
      'status': 'shipped',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchOrders({
    required String userId,
    required String accessToken,
  }) async {
    return {
      'older-order': {
        'datetime': '2026-09-29T10:00:00.000',
        'amount': 50,
        'status': 'delivered',
      },
      'newer-order': {
        'datetime': '2026-09-30T10:00:00.000',
        'amount': 100,
        'status': 'placed',
      },
    };
  }
}

void main() {
  late OrderRepositoryImpl repository;

  setUp(() {
    repository = OrderRepositoryImpl(
      remoteDataSource: _FakeOrderRemoteDataSource(),
    );
  });

  test('preserves Firebase keys and sorts newest orders first', () async {
    final orders = await repository.fetchOrders(
      userId: 'user-1',
      accessToken: 'token',
    );

    expect(orders.length, 2);
    expect(orders.first.id, 'newer-order');
    expect(orders.last.id, 'older-order');
    expect(orders.last.status, OrderStatus.delivered);
  });

  test('injects requested id into a single refreshed order', () async {
    final order = await repository.fetchOrder(
      userId: 'user-1',
      orderId: 'order-123',
      accessToken: 'token',
    );

    expect(order.id, 'order-123');
    expect(order.status, OrderStatus.shipped);
  });
}
