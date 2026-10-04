enum SandboxPaymentStatus { pending, paid, declined, cancelled }

class SandboxPaymentAttempt {
  static const testAmount = 1;
  final String userId;
  final int invoiceId;
  final String reference;
  final Uri paymentUrl;
  final Map<String, dynamic> order;

  SandboxPaymentAttempt({
    required this.userId,
    required this.invoiceId,
    required this.reference,
    required this.paymentUrl,
    required Map<String, dynamic> order,
  }) : order = Map.unmodifiable(order);

  String get orderId => 'sandbox_myfatoorah_$invoiceId';
  double get orderTotal => (order['amount'] as num).toDouble();

  static bool isSandboxUrl(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host.toLowerCase() == 'demo.myfatoorah.com' &&
      uri.userInfo.isEmpty &&
      (!uri.hasPort || uri.port == 443);

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'invoiceId': invoiceId,
    'reference': reference,
    'paymentUrl': paymentUrl.toString(),
    'order': order,
  };

  factory SandboxPaymentAttempt.fromJson(Map<String, dynamic> json) {
    final attempt = SandboxPaymentAttempt(
      userId: json['userId'] as String,
      invoiceId: json['invoiceId'] as int,
      reference: json['reference'] as String,
      paymentUrl: Uri.parse(json['paymentUrl'] as String),
      order: Map<String, dynamic>.from(json['order'] as Map),
    );
    if (attempt.invoiceId <= 0 ||
        !RegExp(r'^MYSHOP-[a-f0-9]{32}$').hasMatch(attempt.reference) ||
        !isSandboxUrl(attempt.paymentUrl) ||
        attempt.order['currency'] != 'EGP' ||
        !attempt.orderTotal.isFinite ||
        attempt.orderTotal <= 0 ||
        attempt.order['products'] is! List ||
        (attempt.order['products'] as List).isEmpty) {
      throw const FormatException('Invalid saved sandbox attempt.');
    }
    return attempt;
  }
}
