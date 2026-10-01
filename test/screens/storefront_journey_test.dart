import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/app/app.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/widgets/product_item.dart';

import '../support/memory_shop_api.dart';

void main() {
  late MemoryShopApi api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'UserData': jsonEncode({
        'token': 'test-token',
        'userId': 'owner',
        'expiryDate': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      }),
    });
    await CacheHelper.init();
    await getIt.reset();
    setup();
    await getIt.unregister<Api>();
    api = MemoryShopApi();
    getIt.registerSingleton<Api>(api);
  });

  tearDown(() async {
    await getIt<AuthProvider>().logOut();
    await getIt.reset();
  });

  Future<void> openApp(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(
          tester.view,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: const MyShopApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final size in [(390.0, 1.0), (320.0, 1.6)]) {
    testWidgets(
      'sample catalog to favorite, cart, COD, and order history at ${size.$1}/${size.$2}',
      (tester) async {
        await openApp(tester, width: size.$1, scale: size.$2);
        expect(find.text('Your storefront starts here'), findsOneWidget);
        await tapText(tester, 'Explore sample collection');
        await tapText(tester, 'Add sample collection');
        expect(api.products.length, 8);
        expect(api.sampleWrites, 8);
        expect(
          api.products.values.every(
            (dynamic item) => item['creatorId'] == 'owner',
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);

        // Repeating setup must preserve an edited price and avoid duplicate writes.
        api.products[sampleCatalog.first.id]['price'] = 155.0;
        await tapText(tester, 'Add sample collection');
        expect(api.sampleWrites, 8);
        expect(api.products[sampleCatalog.first.id]['price'], 155.0);
        await tapText(tester, 'Browse collection');
        await tester.enterText(find.byType(TextField).first, 'Studio stool');
        await tester.pumpAndSettle();
        await tapText(tester, 'Studio stool');
        await tester.tap(find.byTooltip('Save product'));
        await tester.pumpAndSettle();
        expect(api.favorites[sampleCatalog.first.id], isTrue);
        await tapText(tester, 'Add to cart');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Cart');
        expect(find.text('Studio stool'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapText(tester, 'Checkout');
        expect(find.text('Demo Shopper'), findsOneWidget);
        expect(find.text('Cash on delivery'), findsOneWidget);
        final place = find.widgetWithText(FilledButton, 'Place order • \$180');
        await tester.tap(place);
        await tester.pumpAndSettle();
        expect(find.text('Order placed'), findsOneWidget);
        expect(api.orderWrites, 1);
        expect(api.orderUser, 'owner');
        expect(api.placedOrder?['status'], 'placed');
        expect(api.placedOrder?['amount'], 180);
        expect(api.placedOrder?['paymentStatus'], 'cash_on_delivery');
        final cart = tester
            .element(find.text('Order placed'))
            .read<CartProvider>();
        expect(cart.items, isEmpty);
        await tapText(tester, 'Continue');
        await tapText(tester, 'Orders');
        expect(find.text('Your orders'), findsOneWidget);
        expect(find.text('Order #MO-ORDER'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'failed sample setup is retryable without duplicating completed items',
    (tester) async {
      api.failSampleAt = 3;
      await openApp(tester);
      await tapText(tester, 'Explore sample collection');
      await tapText(tester, 'Add sample collection');
      expect(api.products.length, 3);
      expect(
        find.byKey(const ValueKey('sample-catalog-message')),
        findsOneWidget,
      );
      api.failSampleAt = null;
      await tapText(tester, 'Add sample collection');
      expect(api.products.length, 8);
      expect(api.sampleWrites, 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('sold-out listing is visible and cannot be added to the cart', (
    tester,
  ) async {
    final sample = sampleCatalog.last;
    api.products[sample.id] = {
      'id': sample.id,
      'title': sample.title,
      'description': sample.description,
      'imageUrl': '',
      'price': sample.price,
      'category': sample.category,
      'stockQuantity': 0,
      'creatorId': 'owner',
    };
    await openApp(tester, width: 320, scale: 1.6);
    await tester.ensureVisible(find.byType(ProductItem));
    final button = tester.widget<IconButton>(find.byTooltip('Sold out'));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
