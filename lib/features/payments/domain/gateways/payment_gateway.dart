import 'package:shop_application/features/payments/domain/entities/payment_capability.dart';

abstract class PaymentGateway {
  String get providerName;

  bool get isConfigured;

  Set<PaymentCapability> get capabilities;
}
