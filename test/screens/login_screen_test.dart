import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/app/app.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/network/api.dart';

import '../support/auth_test_api.dart';

void main() {
  late AuthTestApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    await getIt.reset();
    setup();
    await getIt.unregister<Api>();
    api = AuthTestApi(
      http.Response(
        jsonEncode({
          'error': {'code': 400, 'message': 'INVALID_LOGIN_CREDENTIALS'},
        }),
        400,
      ),
    );
    getIt.registerSingleton<Api>(api);
  });

  tearDown(() async => getIt.reset());

  testWidgets('failed sign-in shows the cause and preserves entered fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MyShopApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'owner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.first.controller!.text, 'owner@example.com');
    expect(fields.last.controller!.text, 'wrong-password');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(api.calls, 1);
    expect(tester.takeException(), isNull);

    // A retry keeps the same form and produces one more request.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final keyboardHeight in [0.0, 300.0]) {
    testWidgets(
      'compact signup has no overflow with keyboard $keyboardHeight',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: const MyShopApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(TextButton, 'Create account'),
        );
        await tester.tap(find.widgetWithText(TextButton, 'Create account'));
        await tester.pumpAndSettle();

        expect(find.text('Already have an account?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Create account'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
        await tester.pumpAndSettle();
        expect(find.text('Passwords do not match.'), findsNothing);
        expect(find.text('Enter a valid email address.'), findsOneWidget);
        expect(find.text('Use at least 6 characters.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign in'));
        await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(api.calls, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
