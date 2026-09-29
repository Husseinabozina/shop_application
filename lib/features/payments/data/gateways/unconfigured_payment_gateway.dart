import 'package:shop_application/features/payments/domain/entities/payment_capability.dart';
import 'package:shop_application/features/payments/domain/gateways/payment_gateway.dart';

class UnconfiguredPaymentGateway implements PaymentGateway {
  const UnconfiguredPaymentGateway();

  @override
  String get providerName => 'Not configured';

  @override
  bool get isConfigured => false;

  @override
  Set<PaymentCapability> get capabilities => const {};
}
