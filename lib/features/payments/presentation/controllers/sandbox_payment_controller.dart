import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/sandbox_payment.dart';
import '../../domain/repositories/sandbox_checkout_repository.dart';

class SandboxPaymentController extends ChangeNotifier {
  SandboxPaymentController({
    required this.repository,
    required this.userId,
    required this.accessToken,
    required this.onCompleted,
    Future<bool> Function(Uri)? openUrl,
  }) : _openUrl =
           openUrl ??
           ((url) => launchUrl(url, mode: LaunchMode.externalApplication));
  final SandboxCheckoutRepository repository;
  final String? userId;
  final String? accessToken;
  final void Function(SandboxPaymentAttempt) onCompleted;
  final Future<bool> Function(Uri) _openUrl;
  SandboxPaymentAttempt? attempt;
  String? message;
  String? completedOrderId;
  bool isBusy = false;
  bool _disposed = false;
  bool get hasNotice => attempt != null || message != null || isBusy;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restore() async {
    final uid = userId;
    if (uid == null || accessToken == null) return;
    isBusy = true;
    try {
      final restored = await repository.restore(uid);
      if (_disposed) return;
      attempt = restored;
    } catch (_) {
      message =
          'The saved test attempt could not be restored. Your cart is kept.';
    } finally {
      isBusy = false;
      _notify();
    }
    if (!_disposed && attempt != null) await check();
  }

  Future<void> start(Map<String, dynamic> order) async {
    if (isBusy || _disposed || userId == null || accessToken == null) return;
    isBusy = true;
    message = 'Preparing the fixed 1 KWD test payment…';
    completedOrderId = null;
    _notify();
    try {
      final saved = await repository.begin(userId: userId!, order: order);
      if (_disposed) return;
      attempt = saved;
      await _launch(saved);
    } catch (error) {
      message = _error(error);
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> open() async {
    final current = attempt;
    if (current == null || isBusy || _disposed) return;
    isBusy = true;
    _notify();
    try {
      // Persist before opening, including a retry after a local save failure.
      final saved = await repository.begin(
        userId: current.userId,
        order: current.order,
      );
      if (!_disposed) await _launch(saved);
    } catch (error) {
      message = _error(error);
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> _launch(SandboxPaymentAttempt saved) async {
    if (!SandboxPaymentAttempt.isSandboxUrl(saved.paymentUrl))
      throw Exception('Invalid test payment link.');
    if (!await _openUrl(saved.paymentUrl))
      throw Exception(
        'Could not open the browser. Open test payment to try again.',
      );
    if (!_disposed) message = 'Return here after payment. Only a matching Paid invoice creates your demo order.';
  }

  Future<void> check() async {
    final current = attempt;
    final token = accessToken;
    if (current == null || token == null || isBusy || _disposed) return;
    isBusy = true;
    message = 'Checking your test payment…';
    _notify();
    try {
      final status = await repository.checkAndSave(
        attempt: current,
        accessToken: token,
        isCurrentAccount: () => !_disposed && userId == current.userId,
      );
      if (_disposed) return;
      switch (status) {
        case SandboxPaymentStatus.paid:
          completedOrderId = current.orderId;
          attempt = null;
          onCompleted(current);
          message = '1 KWD test payment confirmed. Your demo order is saved in Orders.';
          break;
        case SandboxPaymentStatus.pending:
          message = 'Payment is pending. Your cart and payment link are kept. Check again after completing the test.';
          break;
        case SandboxPaymentStatus.declined:
          message = 'Test payment declined. Your cart is kept. Reopen the saved payment to try again.';
          break;
        case SandboxPaymentStatus.cancelled:
          attempt = null;
          message = 'Test payment cancelled. Your cart is kept; you can start a new attempt.';
          break;
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Sandbox verification failed (${error.runtimeType}).');
        debugPrintStack(stackTrace: stack);
      }
      if (!_disposed) message = _error(error);
    } finally {
      isBusy = false;
      _notify();
    }
  }

  String _error(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ')
        ? text.substring(11)
        : 'Could not check test payment. Your cart and saved attempt are kept. Try again.';
  }

  void dismissNotice() {
    if (attempt == null && !isBusy) {
      message = null;
      completedOrderId = null;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
