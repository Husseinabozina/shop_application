import 'dart:async';
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
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/widgets/product_item.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';

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
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        220,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
    }
    final finder = target.last;
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
        await tester.scrollUntilVisible(
          find.byType(TextField),
          220,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.enterText(find.byType(TextField).first, 'Studio stool');
        await tester.pumpAndSettle();
        final productCard = find.byType(ProductItem);
        await tester.scrollUntilVisible(
          productCard,
          220,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.tap(
          find
              .descendant(of: productCard, matching: find.byType(InkWell))
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProductDetailedScreen), findsOneWidget);
        await tester.tap(find.byTooltip('Save product'));
        await tester.pumpAndSettle();
        expect(api.favorites[sampleCatalog.first.id], isTrue);
        expect(find.byTooltip('Remove from saved'), findsOneWidget);
        expect(api.products[sampleCatalog.first.id].containsKey('isFavorite'), isFalse);
        await tapText(tester, 'Add to cart');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tapText(tester, 'Cart');
        expect(find.text('Studio stool'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapText(tester, 'Checkout');
        expect(find.text('Demo Shopper'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Cash on delivery'),
          220,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
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
        await getIt<AuthProvider>().logOut();
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
      await getIt<AuthProvider>().logOut();
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
    await tester.scrollUntilVisible(
      find.byType(ProductItem),
      220,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    final button = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Sold out',
      ),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await getIt<AuthProvider>().logOut();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed favorite save explains the error and the detail screen can retry', (tester) async {
    api.products['lamp'] = {
      'title': 'Reading lamp', 'description': 'A reading lamp.',
      'imageUrl': '', 'price': 25, 'category': 'Home', 'creatorId': 'owner',
    };
    api.failFavoriteWrites = true;
    await openApp(tester);
    final card = find.byType(ProductItem);
    await tester.scrollUntilVisible(card, 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.tap(find.descendant(of: card, matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save product'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update favorite status.'), findsOneWidget);
    expect(find.byTooltip('Save product'), findsOneWidget);
    expect(api.favorites, isEmpty);
    api.failFavoriteWrites = false;
    await tester.tap(find.byTooltip('Save product'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
    expect(api.favorites['lamp'], isTrue);
    expect(api.favoriteWrites, 2);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await getIt<AuthProvider>().logOut();
    await tester.pumpWidget(const SizedBox.shrink());
  });


  testWidgets('seller can create, edit, and delete a listing through the catalog contract', (tester) async {
    await openApp(tester);
    await tapText(tester, 'Account');
    await tapText(tester, 'Manage products');
    await tapText(tester, 'Add product');

    Future<void> fill(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.scrollUntilVisible(field, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }
    await fill('Product title', 'Seller mug');
    await fill('Price', '24');
    await fill('Category', 'Home');
    await fill('Stock quantity (optional)', '5');
    await fill('Description', 'A useful ceramic mug for your home.');
    await fill('Image URLs', 'https://example.com/mug.jpg');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Seller mug'), findsOneWidget);
    expect(api.products['created-product-1']['creatorId'], 'owner');
    expect(api.products['created-product-1']['price'], 24);
    expect(api.products['created-product-1'].containsKey('isFavorite'), isFalse);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tapText(tester, 'Edit');
    await fill('Price', '30');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();
    expect(api.products['created-product-1']['price'], 30);
    expect(find.text(r'$30'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tapText(tester, 'Delete');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(api.products, isEmpty);
    expect(find.text('No products yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await getIt<AuthProvider>().logOut();
    await tester.pumpWidget(const SizedBox.shrink());
  });


  testWidgets('product details follow listing updates and handle deletion safely', (tester) async {
    api.products['lamp'] = {
      'title': 'Reading lamp', 'description': 'A reading lamp.',
      'imageUrl': '', 'price': 25, 'category': 'Home', 'creatorId': 'owner',
    };
    await openApp(tester);
    final card = find.byType(ProductItem);
    await tester.scrollUntilVisible(card, 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.tap(find.descendant(of: card, matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    final catalog = tester.element(find.byType(ProductDetailedScreen)).read<CatalogController>();
    await catalog.updateProduct(catalog.findById('lamp').copyWith(title: 'Updated lamp', price: 35));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Updated lamp'), 180,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    expect(find.text('Updated lamp'), findsOneWidget);
    expect(find.text(r'$35'), findsOneWidget);
    await catalog.deleteProduct('lamp');
    await tester.pumpAndSettle();
    expect(find.text('This product is no longer available.'), findsOneWidget);
    expect(find.text('Add to cart'), findsNothing);
    expect(tester.takeException(), isNull);
    await getIt<AuthProvider>().logOut();
    await tester.pumpWidget(const SizedBox.shrink());
  });


  testWidgets('failed removal under Saved restores the card and keeps the error visible', (tester) async {
    api.products['lamp'] = {
      'title': 'Reading lamp', 'description': 'A reading lamp.',
      'imageUrl': '', 'price': 25, 'category': 'Home', 'creatorId': 'owner',
    };
    api.favorites['lamp'] = true;
    api.failFavoriteWrites = true;
    api.favoriteWriteGate = Completer<void>();
    await openApp(tester);
    await tester.scrollUntilVisible(find.text('Saved'), 220,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tapText(tester, 'Saved');
    await tester.scrollUntilVisible(find.byType(ProductItem), 180,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.tap(find.byTooltip('Remove from saved'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductItem), findsNothing);
    expect(find.text('No saved products here'), findsOneWidget);
    expect(api.favoriteWrites, 1);
    api.favoriteWriteGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProductItem), findsOneWidget);
    expect(find.text('Could not update favorite status.'), findsOneWidget);
    expect(api.favorites['lamp'], isTrue);
    expect(tester.takeException(), isNull);
    await getIt<AuthProvider>().logOut();
    await tester.pumpWidget(const SizedBox.shrink());
  });

}
