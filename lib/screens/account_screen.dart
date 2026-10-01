import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shop_application/features/address_book/presentation/screens/address_book_screen.dart';
import 'package:shop_application/screens/orders_screen.dart';
import 'package:shop_application/screens/user_product_screen.dart';
import 'package:shop_application/widgets/store_bottom_navigation.dart';

class AccountScreen extends StatelessWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Account'),
      ),
      bottomNavigationBar: const StoreBottomNavigation(
        selectedIndex: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MyShop account',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage delivery, orders, and seller tools.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Shopping',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _AccountTile(
            icon: Icons.location_on_outlined,
            title: 'Saved addresses',
            subtitle: 'Manage delivery locations and your default address',
            onTap: () {
              Navigator.of(context).pushNamed(
                AddressBookScreen.routeName,
              );
            },
          ),
          _AccountTile(
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            subtitle: 'Review purchases and delivery tracking',
            onTap: () {
              Navigator.of(context).pushNamed(
                OrdersScreen.routeName,
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Seller tools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _AccountTile(
            icon: Icons.inventory_2_outlined,
            title: 'Manage products',
            subtitle: 'Create and maintain your own storefront listings',
            onTap: () {
              Navigator.of(context).pushNamed(
                UserProductScreen.routeName,
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Sign out',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthController>().logOut();
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
