import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';

class StoreBottomNavigation extends StatelessWidget {
  final int selectedIndex;

  const StoreBottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  static const _routes = <String>[
    '/',
    '/categories',
    '/cartScreen',
    '/order',
    '/account',
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().cartlengh;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) {
          return;
        }

        final navigator = Navigator.of(context);

        if (index == 0) {
          navigator.popUntil((route) => route.isFirst);
          return;
        }

        navigator.pushNamedAndRemoveUntil(
          _routes[index],
          (route) => route.isFirst,
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Categories',
        ),
        NavigationDestination(
          icon: Badge.count(
            count: cartCount,
            isLabelVisible: cartCount > 0,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          selectedIcon: Badge.count(
            count: cartCount,
            isLabelVisible: cartCount > 0,
            child: const Icon(Icons.shopping_bag_rounded),
          ),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Account',
        ),
      ],
    );
  }
}
