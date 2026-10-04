import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';

import '../../domain/entities/sandbox_payment.dart';
import '../../domain/gateways/sandbox_payment_gateway.dart';
import '../../domain/repositories/sandbox_checkout_repository.dart';
import '../datasources/sandbox_payment_store.dart';

class SandboxCheckoutRepositoryImpl implements SandboxCheckoutRepository {
  SandboxCheckoutRepositoryImpl({
    required this.gateway,
    required this.store,
    required this.database,
  });
  final SandboxPaymentGateway gateway;
  final SandboxPaymentStore store;
  final FirebaseRestClient database;
  final _inFlight = <String, Future<SandboxPaymentAttempt>>{};
  final _unsaved = <String, SandboxPaymentAttempt>{};

  @override
  Future<SandboxPaymentAttempt?> restore(String userId) async =>
      _unsaved[userId] ?? await store.read(userId);

  @override
  Future<SandboxPaymentAttempt> begin({
    required String userId,
    required Map<String, dynamic> order,
  }) async {
    final running = _inFlight[userId];
    if (running != null) return running;
    final future = _begin(userId, order);
    _inFlight[userId] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(userId);
    }
  }

  Future<SandboxPaymentAttempt> _begin(
    String userId,
    Map<String, dynamic> order,
  ) async {
    final existing = await restore(userId);
    if (existing != null) {
      await store.save(existing);
      _unsaved.remove(userId);
      return existing;
    }
    if (order['products'] is! List ||
        (order['products'] as List).isEmpty ||
        order['currency'] != 'EGP' ||
        order['amount'] is! num ||
        !(order['amount'] as num).isFinite ||
        (order['amount'] as num) <= 0) {
      throw Exception('Complete the checkout before starting test payment.');
    }
    final attempt = await gateway.begin(userId: userId, order: order);
    _unsaved[userId] = attempt;
    await store.save(attempt);
    _unsaved.remove(userId);
    return attempt;
  }

  void _assertAccount(bool Function() current) {
    if (!current()) throw Exception('Account changed during test payment.');
  }

  @override
  Future<SandboxPaymentStatus> checkAndSave({
    required SandboxPaymentAttempt attempt,
    required String accessToken,
    required bool Function() isCurrentAccount,
  }) async {
    _assertAccount(isCurrentAccount);
    final status = await gateway.check(attempt);
    _assertAccount(isCurrentAccount);
    if (status == SandboxPaymentStatus.cancelled) {
      await store.remove(attempt.userId);
      return status;
    }
    if (status != SandboxPaymentStatus.paid) return status;
    final payload = {
      ...attempt.order,
      'paymentStatus': 'sandbox_paid',
      'sandboxPayment': {
        'provider': 'MyFatoorah',
        'environment': 'sandbox',
        'invoiceId': attempt.invoiceId,
        'reference': attempt.reference,
        'amount': SandboxPaymentAttempt.testAmount,
        'currency': 'KWD',
      },
    };
    final path = 'order/${attempt.userId}/${attempt.orderId}';
    Future<bool> alreadySaved() async {
      final response = await database.get(path: path, authToken: accessToken);
      if (response.statusCode != 200)
        throw Exception(
          'Test payment confirmed, but your order could not be saved. Check again to retry safely.',
        );
      final existing = jsonDecode(response.body);
      if (existing == null) return false;
      if (existing is! Map ||
          existing['sandboxPayment'] is! Map ||
          existing['sandboxPayment']['invoiceId'] != attempt.invoiceId ||
          existing['sandboxPayment']['reference'] != attempt.reference ||
          existing['amount'] != attempt.orderTotal ||
          existing['currency'] != 'EGP') {
        throw Exception('Saved order does not match this test attempt.');
      }
      return true;
    }

    if (!await alreadySaved()) {
      _assertAccount(isCurrentAccount);
      final response = await database.put(
        path: path,
        data: payload,
        authToken: accessToken,
        ifMatch: 'null_etag',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!await alreadySaved())
          throw Exception(
            'Test payment confirmed, but your order could not be saved. Check again to retry safely.',
          );
      }
    }
    _assertAccount(isCurrentAccount);
    await store.remove(attempt.userId);
    return status;
  }
}
