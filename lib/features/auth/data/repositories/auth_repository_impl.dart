import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shop_application/features/auth/domain/entities/auth_session.dart';
import 'package:shop_application/features/auth/domain/repositories/auth_repository.dart';
import 'package:shop_application/features/auth/domain/repositories/session_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final SessionStore sessionStore;

  const AuthRepositoryImpl({required this.remote, required this.sessionStore});

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      if (error is AuthException) rethrow;
      final failure = ExceptionHandler.handle(error);
      throw AuthException(failure.message,
        errorCode: failure.errorCode, statusCode: failure.statusCode);
    }
  }

  Future<AuthSession> _authenticate(String email, String password, String action) => _run(() async {
    final data = await remote.authenticate(email, password, action);
    final seconds = int.tryParse(data['expiresIn']?.toString() ?? '') ?? 3600;
    final userId = data['localId'];
    final token = data['idToken'];
    if (userId is! String || userId.isEmpty || token is! String || token.isEmpty || seconds <= 0) {
      throw const AuthException('Could not confirm your session. Please sign in again.');
    }
    final session = AuthSession(userId: userId, token: token,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)));
    await sessionStore.save(session);
    return session;
  });

  @override
  Future<AuthSession> login(String email, String password) => _authenticate(email, password, 'signInWithPassword');

  @override
  Future<AuthSession> signup(String email, String password) => _authenticate(email, password, 'signUp');

  @override
  Future<AuthSession?> restoreSession() => _run(() async {
    final session = await sessionStore.load();
    if (session != null && !session.isValid) {
      await sessionStore.clear();
      return null;
    }
    return session;
  });

  @override
  Future<void> logout() => _run(sessionStore.clear);
}
