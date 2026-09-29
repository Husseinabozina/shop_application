import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/widgets/user_produt_Item.dart';

class UserProductScreen extends StatefulWidget {
  static const routeName = '/userproducts';

  const UserProductScreen({super.key});

  @override
  State<UserProductScreen> createState() => _UserProductScreenState();
}

class _UserProductScreenState extends State<UserProductScreen> {
  bool _didLoad = false;
  bool _isLoading = true;

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
      setState(() {
        _isLoading = true;
      });
    }

    await context.read<ProductsProvider>().fetchProducts(
          filterByUser: true,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(EditProductScreen.routeName);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, _) {
          if (_isLoading && provider.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.fetchProductsErrorMessage != null &&
              provider.products.isEmpty) {
            return _ManageProductsError(
              message: provider.fetchProductsErrorMessage!,
              onRetry: _loadProducts,
            );
          }

          if (provider.products.isEmpty) {
            return const _EmptyManagedProducts();
          }

          return RefreshIndicator(
            onRefresh: _loadProducts,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              itemCount: provider.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final product = provider.products[index];

                return UserProductItem(
                  id: product.id,
                  imageUrl: product.imageUrl,
                  title: product.title,
                  category: product.category,
                  price: product.price,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyManagedProducts extends StatelessWidget {
  const _EmptyManagedProducts();

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
              Icons.inventory_2_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to start building the storefront catalog.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageProductsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ManageProductsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await onRetry();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
