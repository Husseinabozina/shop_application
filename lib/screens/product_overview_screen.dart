import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/screens/cart_screen.dart';
import 'package:shop_application/widgets/app_drawer.dart';
import 'package:shop_application/widgets/product_grid.dart';

class ProductOverviewScreen extends StatefulWidget {
  const ProductOverviewScreen({super.key});

  @override
  State<ProductOverviewScreen> createState() => _ProductOverviewScreenState();
}

class _ProductOverviewScreenState extends State<ProductOverviewScreen> {
  bool _isLoading = true;
  bool _didLoad = false;
  bool _favoritesOnly = false;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }

    _didLoad = true;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    await context.read<ProductsProvider>().fetchProducts();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('MyShop'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Badge.count(
                  count: cart.cartlengh,
                  isLabelVisible: cart.cartlengh > 0,
                  child: IconButton(
                    tooltip: 'Cart',
                    onPressed: () {
                      Navigator.of(context).pushNamed(CartScreen.routName);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, _) {
          if (_isLoading && productsProvider.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (productsProvider.fetchProductsErrorMessage != null &&
              productsProvider.products.isEmpty) {
            return _ErrorState(
              message: productsProvider.fetchProductsErrorMessage!,
              onRetry: _loadProducts,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadProducts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Text(
                  'Find something you’ll love',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse the collection, save favorites, and build your cart.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_favoritesOnly,
                      onSelected: (_) {
                        setState(() => _favoritesOnly = false);
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.favorite_border_rounded,
                        size: 18,
                      ),
                      label: const Text('Saved'),
                      selected: _favoritesOnly,
                      onSelected: (_) {
                        setState(() => _favoritesOnly = true);
                      },
                    ),
                    const Spacer(),
                    Text(
                      _visibleCount(productsProvider).toString() + ' items',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ProductsGrid(
                  favoritesOnly: _favoritesOnly,
                  query: _query,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _visibleCount(ProductsProvider provider) {
    final source = _favoritesOnly ? provider.favitem : provider.products;
    final normalized = _query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return source.length;
    }

    return source.where((product) {
      final title = product.title?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      return title.contains(normalized) || description.contains(normalized);
    }).length;
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Couldn’t load products',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
