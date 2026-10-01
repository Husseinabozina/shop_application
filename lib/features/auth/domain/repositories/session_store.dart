import 'package:shop_application/features/auth/domain/entities/auth_session.dart';

abstract class SessionStore {
  Future<AuthSession?> load();
  Future<void> save(AuthSession session);
  Future<void> clear();
}
