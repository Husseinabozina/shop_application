import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/address_book/presentation/screens/address_book_screen.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:shop_application/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:shop_application/features/orders/domain/repositories/order_repository.dart';
import 'package:shop_application/features/orders/presentation/controllers/order_controller.dart';
import 'package:shop_application/screens/account_screen.dart';
import 'package:shop_application/screens/cart_screen.dart';
import 'package:shop_application/screens/categories_screen.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/screens/login_screen.dart';
import 'package:shop_application/screens/orders_screen.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';
import 'package:shop_application/screens/product_overview_screen.dart';
import 'package:shop_application/screens/splash_screen.dart';
import 'package:shop_application/screens/user_product_screen.dart';

class MyShopApp extends StatelessWidget {
  const MyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: getIt<AuthProvider>(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductsProvider>(
          create: (_) => ProductsProvider(productsRepo: getIt<ProductsRepo>()),
          update: (_, auth, __) => ProductsProvider(
            productsRepo: getIt<ProductsRepo>(),
            token: auth.token,
            userId: auth.userId,
          ),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RecentlyViewedController>(
          create: (_) => RecentlyViewedController(
            repository: getIt<RecentlyViewedRepository>(),
          )..load(),
          update: (_, auth, __) => RecentlyViewedController(
            repository: getIt<RecentlyViewedRepository>(),
            userId: auth.userId,
          )..load(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderController>(
          create: (_) => OrderController(repository: getIt<OrderRepository>()),
          update: (_, auth, __) => OrderController(
            repository: getIt<OrderRepository>(),
            token: auth.token,
            userId: auth.userId,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MyShop',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: const _AuthGate(),
            routes: _routes(),
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> _routes() {
    return {
      ProductDetailedScreen.routeName: (_) => const ProductDetailedScreen(),
      CartScreen.routeName: (_) => const CartScreen(),
      CategoriesScreen.routeName: (_) => const CategoriesScreen(),
      AccountScreen.routeName: (_) => const AccountScreen(),
      OrdersScreen.routeName: (_) => const OrdersScreen(),
      UserProductScreen.routeName: (_) => const UserProductScreen(),
      EditProductScreen.routeName: (_) => const EditProductScreen(),
      AddressBookScreen.routeName: _buildAddressBookRoute,
      CheckoutScreen.routeName: _buildCheckoutRoute,
    };
  }

  Widget _buildAddressBookRoute(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    return ChangeNotifierProvider<AddressBookController>(
      create: (_) {
        final controller = getIt<AddressBookController>();
        if (token != null && userId != null) {
          controller.load(userId: userId, accessToken: token);
        }
        return controller;
      },
      child: const AddressBookScreen(),
    );
  }

  Widget _buildCheckoutRoute(BuildContext context) {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    final items = cart.items.entries.map((entry) {
      final item = entry.value;
      return CheckoutLineItem(
        productId: entry.key,
        title: item.title ?? 'Product',
        quantity: item.quantity ?? 1,
        unitPrice: item.price ?? 0,
      );
    }).toList();

    final token = auth.token;
    final userId = auth.userId;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CheckoutController>(
          create: (_) => getIt<CheckoutController>()..initialize(items: items),
        ),
        ChangeNotifierProvider<AddressBookController>(
          create: (_) {
            final controller = getIt<AddressBookController>();
            if (token != null && userId != null) {
              controller.load(userId: userId, accessToken: token);
            }
            return controller;
          },
        ),
      ],
      child: const CheckoutScreen(),
    );
  }
}

/// Restore once so a failed sign-in does not replace and clear the form.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<bool> _restoredSession;

  @override
  void initState() {
    super.initState();
    _restoredSession = context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().isAuth) {
      return const ProductOverviewScreen();
    }

    return FutureBuilder<bool>(
      future: _restoredSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
