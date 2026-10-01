import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';

class _UnusedProductsRepo implements ProductsRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No product requests are needed');
}

class _Products extends ProductsProvider {
  _Products() : super(productsRepo: _UnusedProductsRepo());

  final product = Product(
    id: 'test-product',
    title: 'Test product',
    description: 'A product used only for the navigation regression test.',
    price: 25,
    stockQuantity: 5,
  );

  @override
  Product findById(String id) => product;
}

class _History implements RecentlyViewedRepository {
  List<String> ids = [];
  int saves = 0;

  @override
  List<String> loadProductIds(String scope) => ids;

  @override
  Future<void> saveProductIds(String scope, List<String> productIds) async {
    saves++;
    ids = List.of(productIds);
  }

  @override
  Future<void> clear(String scope) async {
    ids = [];
  }
}

void main() {
  testWidgets(
    'opening product details safely updates existing history listeners',
    (tester) async {
      final history = _History();
      final products = _Products();
      final recent = RecentlyViewedController(
        repository: history,
        userId: 'test-owner',
      )..load();
      final navigator = GlobalKey<NavigatorState>();
      addTearDown(products.dispose);
      addTearDown(products.product.dispose);
      addTearDown(recent.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProductsProvider>.value(value: products),
            ChangeNotifierProvider<RecentlyViewedController>.value(
              value: recent,
            ),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.light(),
            home: Consumer<RecentlyViewedController>(
              builder: (_, value, __) =>
                  Scaffold(body: Text('${value.productIds.length} viewed')),
            ),
            routes: {
              ProductDetailedScreen.routeName: (_) =>
                  const ProductDetailedScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.pushNamed(
        ProductDetailedScreen.routeName,
        arguments: 'test-product',
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Test product'), findsOneWidget);
      expect(recent.productIds, ['test-product']);
      expect(history.ids, ['test-product']);
      expect(history.saves, 1);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('1 viewed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
