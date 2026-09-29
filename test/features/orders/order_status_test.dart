import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';

void main() {
  test('normalizes common backend status values', () {
    expect(orderStatusFromValue('processing'), OrderStatus.placed);
    expect(orderStatusFromValue('dispatched'), OrderStatus.shipped);
    expect(
      orderStatusFromValue('out for delivery'),
      OrderStatus.outForDelivery,
    );
    expect(orderStatusFromValue('delivered'), OrderStatus.delivered);
    expect(orderStatusFromValue('canceled'), OrderStatus.cancelled);
  });

  test('active state excludes delivered and cancelled orders', () {
    expect(OrderStatus.placed.isActive, isTrue);
    expect(OrderStatus.shipped.isActive, isTrue);
    expect(OrderStatus.delivered.isActive, isFalse);
    expect(OrderStatus.cancelled.isActive, isFalse);
  });
}
