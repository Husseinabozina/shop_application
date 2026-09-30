import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/core/config/app_environment.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/data/repos/auth_repo.dart';
import 'package:shop_application/data/services/auth_services.dart';

import '../support/auth_test_api.dart';

void main() {
  late AuthTestApi api;
  late AuthRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    api = AuthTestApi(http.Response('{}', 400));
    repo = AuthRepoImpl(authService: AuthServiceImpl(api));
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

        final result = await repo.signup('owner@example.com', 'test-password');
        result.when(
          success: (_) => fail('The rejected request must not authenticate'),
          failure: (error) {
            expect(error.message, entry.value);
            expect(error.errorCode, entry.key.split(':').first.trim());
            expect(error.statusCode, 400);
            expect(error.details, isNull);
          },
        );
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
      final result = await repo.login('owner@example.com', 'test-password');
      result.when(
        success: (_) => fail('The rejected request must not authenticate'),
        failure: (error) {
          expect(error.errorCode, 'AUTH_REQUEST_FAILED');
          expect(error.statusCode, 400);
          expect(error.message, isNot(contains('owner@example.com')));
          expect(error.message, isNot(contains('test-password')));
          expect(error.details, isNull);
        },
      );
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

        if (signUp) {
          final result = await repo.signup(
            'owner@example.com',
            'test-password',
          );
          result.when(
            success: (account) => expect(account.localId, 'owner-uid'),
            failure: (error) => fail(error.message),
          );
        } else {
          final result = await repo.login('owner@example.com', 'test-password');
          result.when(
            success: (account) => expect(account.localId, 'owner-uid'),
            failure: (error) => fail(error.message),
          );
        }
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
