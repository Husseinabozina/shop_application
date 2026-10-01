import 'package:shop_application/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> signup(String email, String password);
  Future<AuthSession?> restoreSession();
  Future<void> logout();
}

class AuthException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const AuthException(this.message, {this.errorCode, this.statusCode});

  @override
  String toString() => message;
}
