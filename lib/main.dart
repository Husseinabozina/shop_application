import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shop_application/presentation/providers/auth_provider.dart';
import 'package:shop_application/presentation/providers/products_provider.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/helpers/custom_route.dart';
import 'package:shop_application/presentation/providers/cart_provider.dart';
import 'package:shop_application/presentation/providers/order_provider.dart';
import 'package:shop_application/presentation/screens/cart_screen.dart';
import 'package:shop_application/presentation/screens/edit_products_screen.dart';
import 'package:shop_application/presentation/screens/login_screen.dart';
import 'package:shop_application/presentation/screens/orders_screen.dart';
import 'package:shop_application/presentation/screens/product_detailed_screen.dart';
import 'package:shop_application/presentation/screens/splashScreen.dart';
import 'package:shop_application/presentation/screens/user_product_screen.dart';

import 'presentation/screens/product_overview_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: getIt<AuthProvider>(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductsProvider>(
          create: (context) => getIt<ProductsProvider>(),
          update: (ctx, auth, previousproducts) {
            previousproducts?.update(auth.token, auth.userId);
            return previousproducts!;
          },
        ),
        ChangeNotifierProvider.value(value: getIt<CartProvider>()),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => getIt<OrderProvider>(),
          update: (ctx, auth, previousorders) {
            previousorders?.update(auth.token, auth.userId);
            return previousorders!;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: ((context, auth, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MyShop',
              theme: ThemeData(
                  primarySwatch: Colors.cyan,
                  fontFamily: 'Lato',
                  pageTransitionsTheme: PageTransitionsTheme(builders: {
                    TargetPlatform.android: CustomPageTransitionBuilder(),
                    TargetPlatform.iOS: CustomPageTransitionBuilder(),
                  })),
              home: auth.isAuth
                  ? ProductOverviewScreen()
                  : FutureBuilder(
                      future: auth.tryAutoLogin(),
                      builder: (ctx, authsnapshot) =>
                          authsnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? const SplashScreen()
                              : LoginScreen()),
              routes: {
                ProductDetailedScreen.routename: (context) =>
                    const ProductDetailedScreen(),
                CartScreen.routName: (context) => const CartScreen(),
                OrdersScreen.routeName: (context) => const OrdersScreen(),
                UserProductScreen.routeName: (context) =>
                    const UserProductScreen(),
                EditProductScreen.routeName: (context) =>
                    const EditProductScreen()
              },
            )),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyShop'),
      ),
      body: const Center(
        child: Text('Let\'s build a shop!'),
      ),
    );
  }
}
