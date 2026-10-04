import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shop_application/features/cart/presentation/controllers/cart_controller.dart';
import 'package:shop_application/features/cart/domain/repositories/cart_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/address_book/presentation/screens/address_book_screen.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/features/catalog/presentation/controllers/sample_catalog_controller.dart';
import 'package:shop_application/features/catalog/presentation/screens/sample_catalog_screen.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:shop_application/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:shop_application/features/payments/domain/repositories/sandbox_checkout_repository.dart';
import 'package:shop_application/features/payments/presentation/controllers/sandbox_payment_controller.dart';
import 'package:shop_application/features/payments/presentation/widgets/sandbox_payment_host.dart';
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
        ChangeNotifierProvider<AuthController>.value(
          value: getIt<AuthController>(),
        ),
        ChangeNotifierProxyProvider<AuthController, CatalogController>(
          create: (_) =>
              CatalogController(repository: getIt<ProductRepository>()),
          update: (_, auth, previous) =>
              previous?.userId == auth.userId && previous?.token == auth.token
              ? previous!
              : CatalogController(
                  repository: getIt<ProductRepository>(),
                  token: auth.token,
                  userId: auth.userId,
                ),
        ),
        ChangeNotifierProxyProvider<AuthController, CartController>(
          create: (_) => CartController(repository: getIt<CartRepository>()),
          update: (_, auth, previous) => previous?.userId == auth.userId
              ? previous!
              : CartController(
                  repository: getIt<CartRepository>(),
                  userId: auth.userId,
                ),
        ),
        ChangeNotifierProxyProvider<AuthController, RecentlyViewedController>(
          create: (_) => RecentlyViewedController(
            repository: getIt<RecentlyViewedRepository>(),
          )..load(),
          update: (_, auth, previous) =>
              previous?.userId == auth.userId
                    ? previous!
                    : RecentlyViewedController(
                        repository: getIt<RecentlyViewedRepository>(),
                        userId: auth.userId,
                      )
                ..load(),
        ),
        ChangeNotifierProxyProvider<AuthController, SandboxPaymentController>(
          create: (_) => SandboxPaymentController(
            repository: getIt<SandboxCheckoutRepository>(),
            userId: null,
            accessToken: null,
            onCompleted: (_) {},
          ),
          update: (context, auth, previous) {
            if (previous?.userId == auth.userId &&
                previous?.accessToken == auth.token)
              return previous!;
            return SandboxPaymentController(
              repository: getIt<SandboxCheckoutRepository>(),
              userId: auth.userId,
              accessToken: auth.token,
              onCompleted: (attempt) {
                final cart = context.read<CartController>();
                final purchased = (attempt.order['products'] as List)
                    .whereType<Map>()
                    .toList();
                // Preserve a newer basket if the shopper changed it while payment was open.
                if (cart.userId == attempt.userId &&
                    cart.items.length == purchased.length &&
                    purchased.every((item) {
                      final current = cart.items[item['id']];
                      return current != null &&
                          current.quantity == item['quantity'] &&
                          current.price == item['price'];
                    }))
                  cart.clear();
              },
            )..restore();
          },
        ),
        ChangeNotifierProxyProvider<AuthController, OrderController>(
          create: (_) => OrderController(repository: getIt<OrderRepository>()),
          update: (_, auth, previous) =>
              previous?.userId == auth.userId && previous?.token == auth.token
              ? previous!
              : OrderController(
                  repository: getIt<OrderRepository>(),
                  token: auth.token,
                  userId: auth.userId,
                ),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp(
            key: ValueKey(auth.userId ?? 'signed-out'),
            debugShowCheckedModeBanner: false,
            title: 'MyShop',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            builder: (_, child) =>
                SandboxPaymentHost(child: child ?? const SizedBox.shrink()),
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
      SampleCatalogScreen.routeName: (_) => ChangeNotifierProvider(
        create: (_) => getIt<SampleCatalogController>(),
        child: const SampleCatalogScreen(),
      ),
      AddressBookScreen.routeName: _buildAddressBookRoute,
      CheckoutScreen.routeName: _buildCheckoutRoute,
    };
  }

  Widget _buildAddressBookRoute(BuildContext context) {
    final auth = context.read<AuthController>();
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
    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();

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
    final auth = context.read<AuthController>();
    _restoredSession = auth.isAuth ? Future.value(true) : auth.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthController>().isAuth) {
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
