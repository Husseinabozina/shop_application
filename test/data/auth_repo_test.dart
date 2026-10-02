import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/core/config/app_environment.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/features/auth/domain/repositories/auth_repository.dart';
import 'package:shop_application/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shop_application/features/auth/data/datasources/local_session_store.dart';
import 'package:shop_application/features/auth/data/datasources/auth_remote_data_source.dart';

import '../support/auth_test_api.dart';

void main() {
  late AuthTestApi api;
  late AuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = AuthTestApi(http.Response('{}', 400));
    repo = AuthRepositoryImpl(remote: FirebaseAuthRemoteDataSource(api), sessionStore: LocalSessionStore());
  });

  test('handling an APIException preserves its code and message', () {
    final failure = APIException(
      message: 'The email or password is incorrect.',
      errorCode: 'INVALID_LOGIN_CREDENTIALS',
      statusCode: 400,
    );
    expect(ExceptionHandler.handle(failure), same(failure));
  });

  for (final entry in {
    'EMAIL_EXISTS': 'This email already has an account. Sign in instead.',
    'INVALID_LOGIN_CREDENTIALS': 'The email or password is incorrect.',
    'INVALID_PASSWORD': 'The email or password is incorrect.',
    'EMAIL_NOT_FOUND': 'The email or password is incorrect.',
    'INVALID_EMAIL': 'Enter a valid email address.',
    'WEAK_PASSWORD : Password should be at least 6 characters':
        'Choose a stronger password with at least 6 characters.',
    'OPERATION_NOT_ALLOWED':
        'Email and password sign-in is unavailable. Contact support.',
  }.entries) {
    test(
      'Firebase ${entry.key} survives service and repository handling',
      () async {
        api.response = http.Response(
          jsonEncode({
            'error': {'code': 400, 'message': entry.key},
          }),
          400,
        );

        await expectLater(repo.signup('owner@example.com', 'test-password'),
          throwsA(isA<AuthException>()
            .having((e) => e.message, 'message', entry.value)
            .having((e) => e.errorCode, 'code', entry.key.split(':').first.trim())
            .having((e) => e.statusCode, 'status', 400)));
        expect(CacheHelper.isLoggedIn(), isFalse);
      },
    );
  }

  for (final body in [
    'not JSON',
    '{}',
    '{"error":"unavailable"}',
    '{"error":{"message":"UNKNOWN: owner@example.com test-password"}}',
  ]) {
    test('unexpected auth response uses a safe fallback: $body', () async {
      api.response = http.Response(body, 400);
      await expectLater(repo.login('owner@example.com', 'test-password'),
        throwsA(isA<AuthException>()
          .having((e) => e.errorCode, 'code', 'AUTH_REQUEST_FAILED')
          .having((e) => e.message, 'safe email', isNot(contains('owner@example.com')))
          .having((e) => e.message, 'safe password', isNot(contains('test-password')))
          .having((e) => e.statusCode, 'status', 400)));

    });
  }

  for (final signUp in [true, false]) {
    test(
      '${signUp ? 'signup' : 'login'} accepts a response without legacy kind',
      () async {
        api.response = http.Response(
          jsonEncode({
            'idToken': 'test-id-token',
            'localId': 'owner-uid',
            'email': 'owner@example.com',
            'refreshToken': 'test-refresh-token',
            'expiresIn': '3600',
          }),
          200,
        );

        final account = signUp
            ? await repo.signup('owner@example.com', 'test-password')
            : await repo.login('owner@example.com', 'test-password');
        expect(account.userId, 'owner-uid');
        expect(
          api.lastUrl,
          endsWith(signUp ? 'accounts:signUp' : 'accounts:signInWithPassword'),
        );
        expect(api.lastQuery?['key'], AppEnvironment.firebaseWebApiKey);
        expect(api.lastData, {
          'email': 'owner@example.com',
          'password': 'test-password',
          'returnSecureToken': true,
        });
        final cached = await CacheHelper.getUserData();
        expect(cached['userId'], 'owner-uid');
        expect(cached['token'], 'test-id-token');
      },
    );
  }
}
