import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/app/app.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/screens/login_screen.dart';
import 'package:shop_application/screens/onboarding_screen.dart';
import 'package:shop_application/screens/splash_screen.dart';

import '../support/portfolio_capture.dart';

void main() {
  setUpAll(preparePortfolioCapture);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    await getIt.reset();
    setup();
  });
  tearDown(() => getIt.reset());

  Future<void> ready(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'cold launch shows branding, completes three pages, and remembers the welcome flow after restart',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const RepaintBoundary(
      key: ValueKey('portfolio-capture'),
      child: MyShopApp(),
    ));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SplashScreen), findsOneWidget);
    await capturePortfolio(tester, '08-splash');
    await ready(tester);
    expect(find.text('Find your next favourite'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(CacheHelper.hasCompletedOnboarding, isFalse);
    await capturePortfolio(tester, '09-onboarding-discover');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your basket, your way'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your orders close'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(CacheHelper.hasCompletedOnboarding, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await CacheHelper.init();
    await tester.pumpWidget(const MyShopApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await ready(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Skip saves completion on a compact phone with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: const TextScaler.linear(1.6)),
      child: const MyShopApp(),
    ));
    await ready(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(CacheHelper.hasCompletedOnboarding, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed preference save keeps onboarding available for retry',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: OnboardingScreen(onCompleted: () async {
        attempts++;
        if (attempts == 1) throw StateError('Storage failed');
      }),
    ));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save your preferences. Please try again.'),
        findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Could not save your preferences. Please try again.'),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
