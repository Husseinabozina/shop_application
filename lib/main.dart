import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/order_provider/order_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/screens/cart_screen.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/screens/login_screen.dart';
import 'package:shop_application/screens/orders_screen.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';
import 'package:shop_application/screens/product_overview_screen.dart';
import 'package:shop_application/screens/splashScreen.dart';
import 'package:shop_application/screens/user_product_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: getIt<AuthProvider>(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductsProvider>(
          create: (_) => ProductsProvider(
            productsRepo: getIt<ProductsRepo>(),
          ),
          update: (_, auth, __) => ProductsProvider(
            productsRepo: getIt<ProductsRepo>(),
            token: auth.token,
            userId: auth.userId,
          ),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(
            orderRepo: getIt<OrderRepo>(),
          ),
          update: (_, auth, __) => OrderProvider(
            orderRepo: getIt<OrderRepo>(),
            token: auth.token,
            userId: auth.userId,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MyShop',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: auth.isAuth
              ? const ProductOverviewScreen()
              : FutureBuilder<bool>(
                  future: auth.tryAutoLogin(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SplashScreen();
                    }
                    return LoginScreen();
                  },
                ),
          routes: {
            ProductDetailedScreen.routename: (_) =>
                const ProductDetailedScreen(),
            CartScreen.routName: (_) => const CartScreen(),
            OrdersScreen.routeName: (_) => const OrdersScreen(),
            UserProductScreen.routeName: (_) => const UserProductScreen(),
            EditProductScreen.routeName: (_) => const EditProductScreen(),
          },
        ),
      ),
    );
  }
}
