import '../entities/sandbox_payment.dart';

abstract class SandboxCheckoutRepository {
  Future<SandboxPaymentAttempt?> restore(String userId);
  Future<SandboxPaymentAttempt> begin({
    required String userId,
    required Map<String, dynamic> order,
  });
  Future<SandboxPaymentStatus> checkAndSave({
    required SandboxPaymentAttempt attempt,
    required String accessToken,
    required bool Function() isCurrentAccount,
  });
}
