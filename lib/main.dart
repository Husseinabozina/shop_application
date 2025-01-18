import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/helpers/custom_route.dart';
import 'package:shop_application/provider/auth.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/provider/order.dart';
import 'package:shop_application/provider/products.dart';
import 'package:shop_application/screens/cart_screen.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/screens/login_screen.dart';
import 'package:shop_application/screens/orders_screen.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';
import 'package:shop_application/screens/splashScreen.dart';
import 'package:shop_application/screens/user_product_screen.dart';

import 'screens/product_overview_screen.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

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
          update: (ctx, auth, previousproducts) => getIt<ProductsProvider>(),
        ),
        ChangeNotifierProvider.value(value: CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, Orders>(
            create: (context) => Orders("", "", []),
            update: (ctx, auth, previousorders) => Orders(
                auth.token,
                auth.userId,
                previousorders == null ? [] : previousorders.orders))
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
