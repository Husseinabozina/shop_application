import '../entities/sandbox_payment.dart';
import 'payment_gateway.dart';

abstract class SandboxPaymentGateway implements PaymentGateway {
  Future<SandboxPaymentAttempt> begin({
    required String userId,
    required Map<String, dynamic> order,
  });
  Future<SandboxPaymentStatus> check(SandboxPaymentAttempt attempt);
}
