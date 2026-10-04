import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../domain/entities/payment_capability.dart';
import '../../domain/entities/sandbox_payment.dart';
import '../../domain/gateways/sandbox_payment_gateway.dart';

/// Public documentation token ONLY. No private merchant token or live override.
class MyFatoorahSandboxGateway implements SandboxPaymentGateway {
  MyFatoorahSandboxGateway({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = 'https://apitest.myfatoorah.com';
  static const _publicToken =
      'SK_KWT_vVZlnnAqu8jRByOWaRPNId4ShzEDNt256dvnjebuyzo52dXjAfRx2ixW5umjWSUx';

  @override
  String get providerName => 'MyFatoorah Sandbox';
  @override
  bool get isConfigured => true;
  @override
  Set<PaymentCapability> get capabilities => const {PaymentCapability.card};
  void close() => _client.close();

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    // Refuse redirects: neither the public credential nor payment flow goes live.
    final request = http.Request('POST', Uri.parse('$baseUrl/v2/$endpoint'))
      ..followRedirects = false
      ..headers.addAll({
        'Authorization': 'Bearer $_publicToken',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Test payment is unavailable. Your cart and saved attempt are kept.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map ||
        decoded['IsSuccess'] != true ||
        decoded['Data'] is! Map) {
      throw Exception(
        'MyFatoorah could not complete this test request. Try again.',
      );
    }
    return Map<String, dynamic>.from(decoded['Data'] as Map);
  }

  @override
  Future<SandboxPaymentAttempt> begin({
    required String userId,
    required Map<String, dynamic> order,
  }) async {
    final methods = await _post('InitiatePayment', {
      'InvoiceAmount': SandboxPaymentAttempt.testAmount,
      'CurrencyIso': 'KWD',
    });
    final cards = (methods['PaymentMethods'] as List? ?? [])
        .whereType<Map>()
        .where(
          (m) =>
              m['PaymentMethodEn'] == 'VISA/MASTER' &&
              m['IsDirectPayment'] != true,
        );
    if (cards.isEmpty || cards.first['PaymentMethodId'] is! int) {
      throw Exception('Hosted test card payments are unavailable.');
    }
    final random = Random.secure();
    final reference =
        'MYSHOP-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    final invoice = await _post('ExecutePayment', {
      'PaymentMethodId': cards.first['PaymentMethodId'],
      'InvoiceValue': SandboxPaymentAttempt.testAmount,
      'DisplayCurrencyIso': 'KWD', 'CustomerName': 'MyShop Demo',
      'Language': 'AR', 'CustomerReference': reference,
      // Never send cart, address, phone, email, or card details to the shared merchant.
    });
    final id = invoice['InvoiceId'];
    final url = Uri.tryParse(invoice['PaymentURL']?.toString() ?? '');
    if (id is! int ||
        id <= 0 ||
        url == null ||
        !SandboxPaymentAttempt.isSandboxUrl(url) ||
        invoice['IsDirectPayment'] == true ||
        invoice['CustomerReference'] != reference) {
      throw Exception('MyFatoorah returned an invalid test invoice.');
    }
    return SandboxPaymentAttempt(
      userId: userId,
      invoiceId: id,
      reference: reference,
      paymentUrl: url,
      order: order,
    );
  }

  @override
  Future<SandboxPaymentStatus> check(SandboxPaymentAttempt attempt) async {
    final data = await _post('GetPaymentStatus', {
      'Key': attempt.invoiceId.toString(),
      'KeyType': 'InvoiceId',
    });
    final display = data['InvoiceDisplayValue']?.toString().trim() ?? '';
    if (data['InvoiceId'] != attempt.invoiceId ||
        data['CustomerReference'] != attempt.reference ||
        data['InvoiceValue'] is! num ||
        data['InvoiceValue'] != SandboxPaymentAttempt.testAmount ||
        !RegExp(r'^1(?:\.0+)?\s+(?:KD|KWD)$').hasMatch(display)) {
      throw Exception(
        'Test receipt does not match the saved attempt. No order was created.',
      );
    }
    switch (data['InvoiceStatus']) {
      case 'Paid':
        return SandboxPaymentStatus.paid;
      case 'Canceled':
      case 'Cancelled':
        return SandboxPaymentStatus.cancelled;
      case 'Pending':
        final transactions = data['InvoiceTransactions'] as List? ?? [];
        return transactions.isNotEmpty &&
                transactions.last is Map &&
                transactions.last['TransactionStatus'] == 'Failed'
            ? SandboxPaymentStatus.declined
            : SandboxPaymentStatus.pending;
      default:
        throw Exception('Unrecognized test payment result. Check again later.');
    }
  }
}
