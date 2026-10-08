import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/sandbox_payment.dart';

class SandboxPaymentStore {
  String _key(String userId) => 'myshop_sandbox_attempt_v1_$userId';

  Future<SandboxPaymentAttempt?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return null;
    final attempt = SandboxPaymentAttempt.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    if (attempt.userId != userId)
      throw Exception('Saved payment belongs to another account.');
    return attempt;
  }

  Future<void> save(SandboxPaymentAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key(attempt.userId),
      jsonEncode(attempt.toJson()),
    )) {
      throw Exception(
        'Could not save the test attempt. Retry before opening payment.',
      );
    }
  }

  Future<void> remove(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_key(userId)))
      throw Exception('Could not clear the completed test attempt.');
  }
}
