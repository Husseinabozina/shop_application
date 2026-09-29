import 'package:shop_application/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:shop_application/features/payments/domain/entities/payment_capability.dart';
import 'package:shop_application/features/payments/domain/gateways/payment_gateway.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource remoteDataSource;
  final PaymentGateway paymentGateway;

  CheckoutRepositoryImpl({
    required this.remoteDataSource,
    required this.paymentGateway,
  });

  @override
  Future<List<ShippingMethod>> getShippingMethods({
    required CheckoutAddress address,
    required List<CheckoutLineItem> items,
  }) async {
    final subtotal = items.fold<double>(
      0,
      (total, item) => total + item.total,
    );

    final standardPrice = subtotal >= 500 ? 0.0 : 25.0;

    return [
      ShippingMethod(
        id: 'standard',
        title: 'Standard delivery',
        description: subtotal >= 500
            ? 'Free delivery unlocked'
            : 'Reliable tracked delivery',
        price: standardPrice,
        minDeliveryDays: 3,
        maxDeliveryDays: 5,
      ),
      const ShippingMethod(
        id: 'express',
        title: 'Express delivery',
        description: 'Priority delivery for faster arrival',
        price: 55,
        minDeliveryDays: 1,
        maxDeliveryDays: 2,
      ),
    ];
  }

  @override
  Future<List<PaymentMethodOption>> getPaymentMethods() async {
    final gatewayReady = paymentGateway.isConfigured;
    final supportsCard =
        gatewayReady &&
        paymentGateway.capabilities.contains(PaymentCapability.card);
    final supportsWallet =
        gatewayReady &&
        paymentGateway.capabilities.contains(PaymentCapability.wallet);

    return [
      const PaymentMethodOption(
        id: 'cod',
        type: PaymentMethodType.cashOnDelivery,
        title: 'Cash on delivery',
        description: 'Pay when your order arrives',
      ),
      PaymentMethodOption(
        id: 'card',
        type: PaymentMethodType.card,
        title: 'Card payment',
        description: supportsCard
            ? 'Secure card payment via ${paymentGateway.providerName}'
            : 'Secure gateway connection required',
        isEnabled: supportsCard,
      ),
      PaymentMethodOption(
        id: 'wallet',
        type: PaymentMethodType.digitalWallet,
        title: 'Digital wallet',
        description: supportsWallet
            ? 'Wallet payment via ${paymentGateway.providerName}'
            : 'Wallet gateway connection required',
        isEnabled: supportsWallet,
      ),
    ];
  }

  @override
  Future<PromoCodeResult> applyPromoCode({
    required String code,
    required double subtotal,
  }) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode == 'WELCOME10') {
      final discount = subtotal * 0.10;
      return PromoCodeResult(
        code: normalizedCode,
        discountAmount: discount,
        freeShipping: false,
        message: '10% discount applied.',
      );
    }

    if (normalizedCode == 'FREESHIP') {
      return PromoCodeResult(
        code: normalizedCode,
        discountAmount: 0,
        freeShipping: true,
        message: 'Free shipping applied.',
      );
    }

    throw Exception('Promo code is not valid.');
  }

  @override
  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  }) {
    return remoteDataSource.placeOrder(
      order: order,
      userId: userId,
      accessToken: accessToken,
    );
  }
}
