import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:shop_application/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';

class _FakeCheckoutRemoteDataSource implements CheckoutRemoteDataSource {
  @override
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  }) async {
    return const CheckoutResult(orderId: 'test-order');
  }
}

void main() {
  late CheckoutRepositoryImpl repository;

  setUp(() {
    repository = CheckoutRepositoryImpl(
      remoteDataSource: _FakeCheckoutRemoteDataSource(),
    );
  });

  test('standard shipping becomes free at the threshold', () async {
    final methods = await repository.getShippingMethods(
      address: const CheckoutAddress(
        fullName: 'Test User',
        phone: '01000000000',
        addressLine1: 'Main Street',
        city: 'Cairo',
        country: 'Egypt',
      ),
      items: const [
        CheckoutLineItem(
          productId: 'p1',
          title: 'Product',
          quantity: 1,
          unitPrice: 500,
        ),
      ],
    );

    expect(methods.first.id, 'standard');
    expect(methods.first.price, 0);
  });

  test('cash on delivery is enabled while gateways stay disabled', () async {
    final methods = await repository.getPaymentMethods();

    expect(
      methods.firstWhere((method) => method.id == 'cod').isEnabled,
      isTrue,
    );
    expect(
      methods.firstWhere((method) => method.id == 'card').isEnabled,
      isFalse,
    );
    expect(
      methods.firstWhere((method) => method.id == 'wallet').isEnabled,
      isFalse,
    );
  });

  test('WELCOME10 applies a ten percent discount', () async {
    final result = await repository.applyPromoCode(
      code: 'welcome10',
      subtotal: 800,
    );

    expect(result.code, 'WELCOME10');
    expect(result.discountAmount, 80);
    expect(result.freeShipping, isFalse);
  });

  test('FREESHIP removes shipping cost', () async {
    final result = await repository.applyPromoCode(
      code: 'freeship',
      subtotal: 200,
    );

    expect(result.freeShipping, isTrue);
    expect(result.discountAmount, 0);
  });
}
