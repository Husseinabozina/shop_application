import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/features/auth/domain/entities/auth_session.dart';
import 'package:shop_application/features/auth/domain/repositories/session_store.dart';

/// Retains the existing UserData format so installed sessions survive migration.
class LocalSessionStore implements SessionStore {
  @override
  Future<AuthSession?> load() async {
    if (!CacheHelper.isLoggedIn()) return null;
    try {
      final data = await CacheHelper.getUserData();
      final expiresAt = DateTime.tryParse(data['expiryDate']?.toString() ?? '');
      final userId = data['userId'];
      final token = data['token'];
      if (expiresAt == null || userId is! String || token is! String) {
        await clear();
        return null;
      }
      return AuthSession(userId: userId, token: token, expiresAt: expiresAt);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(AuthSession session) => CacheHelper.saveUserData(
    session.token, session.userId, session.expiresAt,
  );

  @override
  Future<void> clear() => CacheHelper.clearUserData();
}
