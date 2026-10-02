import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/features/auth/domain/entities/auth_session.dart';
import 'package:shop_application/features/auth/domain/repositories/auth_repository.dart';

class AuthController with ChangeNotifier {
  final AuthRepository repository;

  AuthController({required this.repository});

  AuthSession? _session;
  Timer? _timer;
  bool _disposed = false;
  bool _busy = false;
  String? _successMessage;
  String? _failureMessage;

  bool get isAuth => _session?.isValid == true;
  String? get token => isAuth ? _session!.token : null;
  String? get userId => isAuth ? _session!.userId : null;
  String? get successMessage => _successMessage;
  String? get failureMessage => _failureMessage;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setSession(AuthSession session) {
    _session = session;
    _timer?.cancel();
    final remaining = session.expiresAt.difference(DateTime.now());
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, logOut);
  }

  Future<void> _authenticate(String email, String password, {required bool signup}) async {
    if (_busy || _disposed) return;
    _busy = true;
    _failureMessage = null;
    _successMessage = null;
    try {
      final session = signup
          ? await repository.signup(email, password)
          : await repository.login(email, password);
      if (_disposed) return;
      _setSession(session);
      _successMessage = signup ? AppStrings.signUpSuccessMessage : AppStrings.loginSuccessMessage;
    } on AuthException catch (error) {
      if (_disposed) return;
      _failureMessage = error.message;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> login(String email, String password) => _authenticate(email, password, signup: false);
  Future<void> signup(String email, String password) => _authenticate(email, password, signup: true);

  Future<bool> tryAutoLogin() async {
    try {
      final session = await repository.restoreSession();
      if (_disposed || session == null) return false;
      _setSession(session);
      _notify();
      return true;
    } on AuthException catch (error) {
      if (!_disposed) _failureMessage = error.message;
      return false;
    }
  }

  Future<void> logOut() async {
    _session = null;
    _timer?.cancel();
    _timer = null;
    _successMessage = null;
    _failureMessage = null;
    _notify();
    try {
      await repository.logout();
    } on AuthException catch (error) {
      if (!_disposed) {
        _failureMessage = error.message;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
