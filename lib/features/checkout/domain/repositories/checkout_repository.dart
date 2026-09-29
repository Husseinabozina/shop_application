import '../entities/checkout_models.dart';

abstract class CheckoutRepository {
  Future<List<ShippingMethod>> getShippingMethods({
    required CheckoutAddress address,
    required List<CheckoutLineItem> items,
  });

  Future<List<PaymentMethodOption>> getPaymentMethods();

  Future<PromoCodeResult> applyPromoCode({
    required String code,
    required double subtotal,
  });

  Future<CheckoutResult> placeOrder({
    required CheckoutOrderDraft order,
    required String userId,
    required String accessToken,
  });
}
