import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';

void main() {
  group('CheckoutTotals', () {
    test('calculates subtotal, shipping, discount, and total', () {
      const totals = CheckoutTotals(
        subtotal: 500,
        shipping: 25,
        discount: 50,
      );

      expect(totals.total, 475);
    });

    test('never returns a negative total', () {
      const totals = CheckoutTotals(
        subtotal: 20,
        shipping: 0,
        discount: 100,
      );

      expect(totals.total, 0);
    });
  });

  test('order payload keeps checkout metadata and legacy products', () {
    const order = CheckoutOrderDraft(
      items: [
        CheckoutLineItem(
          productId: 'product-1',
          title: 'Test product',
          quantity: 2,
          unitPrice: 100,
        ),
      ],
      address: CheckoutAddress(
        fullName: 'Test User',
        phone: '01000000000',
        addressLine1: 'Main Street',
        city: 'Cairo',
        country: 'Egypt',
      ),
      shippingMethod: ShippingMethod(
        id: 'standard',
        title: 'Standard delivery',
        description: 'Tracked delivery',
        price: 25,
        minDeliveryDays: 3,
        maxDeliveryDays: 5,
      ),
      paymentMethod: PaymentMethodOption(
        id: 'cod',
        type: PaymentMethodType.cashOnDelivery,
        title: 'Cash on delivery',
        description: 'Pay on arrival',
      ),
      totals: CheckoutTotals(
        subtotal: 200,
        shipping: 25,
        discount: 0,
      ),
    );

    final json = order.toJson();

    expect(json['amount'], 225);
    expect(json['status'], 'placed');
    expect(json['paymentStatus'], 'cash_on_delivery');
    expect(json['shippingAddress'], isA<Map<String, dynamic>>());
    expect(json['products'], isA<List<dynamic>>());
    expect((json['products'] as List).length, 1);
  });
}
