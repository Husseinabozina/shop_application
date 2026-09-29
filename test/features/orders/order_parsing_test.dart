import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';

void main() {
  test('parses tracked checkout metadata', () {
    final order = Order.fromJson({
      'id': 'order-123',
      'datetime': '2026-09-30T10:00:00.000',
      'amount': 250,
      'status': 'shipped',
      'paymentStatus': 'cash_on_delivery',
      'estimatedDeliveryStart': '2026-10-01T10:00:00.000',
      'estimatedDeliveryEnd': '2026-10-02T10:00:00.000',
      'shippingMethod': {
        'title': 'Express delivery',
        'minDeliveryDays': 1,
        'maxDeliveryDays': 2,
      },
      'paymentMethod': {
        'title': 'Cash on delivery',
      },
      'shippingAddress': {
        'fullName': 'Test User',
        'phone': '01000000000',
        'addressLine1': 'Main Street',
        'city': 'Cairo',
        'country': 'Egypt',
      },
      'statusHistory': {
        'placed': '2026-09-30T10:00:00.000',
        'shipped': '2026-09-30T15:00:00.000',
      },
      'products': [
        {
          'id': 'p1',
          'title': 'Product',
          'quantity': 2,
          'price': 100,
        },
      ],
    });

    expect(order.id, 'order-123');
    expect(order.status, OrderStatus.shipped);
    expect(order.shippingMethodTitle, 'Express delivery');
    expect(order.paymentMethodTitle, 'Cash on delivery');
    expect(order.deliveryAddress, 'Main Street, Cairo, Egypt');
    expect(order.statusHistory[OrderStatus.shipped], isNotNull);
    expect(order.products?.first.quantity, 2);
  });

  test('keeps compatibility with legacy quantity typo', () {
    final order = Order.fromJson({
      'datetime': '2026-09-30T10:00:00.000',
      'amount': 100,
      'products': [
        {
          'id': 'p1',
          'title': 'Legacy product',
          'quantitiy': 3,
          'price': 25,
        },
      ],
    });

    expect(order.status, OrderStatus.placed);
    expect(order.products?.first.quantity, 3);
  });

  test('derives ETA from shipping days when explicit dates are missing', () {
    final order = Order.fromJson({
      'datetime': '2026-09-30T10:00:00.000',
      'amount': 100,
      'shippingMethod': {
        'title': 'Standard delivery',
        'minDeliveryDays': 3,
        'maxDeliveryDays': 5,
      },
    });

    expect(
      order.estimatedDeliveryStart,
      DateTime.parse('2026-10-03T10:00:00.000'),
    );
    expect(
      order.estimatedDeliveryEnd,
      DateTime.parse('2026-10-05T10:00:00.000'),
    );
  });
}
