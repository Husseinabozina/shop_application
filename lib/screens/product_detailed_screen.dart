import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/provider/product.dart';

class ProductDetailedScreen extends StatelessWidget {
  static const routename = '/ProductDetailed';

  const ProductDetailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final product = context.read<ProductsProvider>().findById(productId);

    return ChangeNotifierProvider<Product>.value(
      value: product,
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = context.watch<Product>();
    final imageUrl = product.imageUrl?.trim() ?? '';
    final heroTag = product.id ?? product.productId ?? product.title ?? '';

    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: FilledButton.icon(
          onPressed: () => _addToCart(context, product),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Add to cart'),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 420,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  tooltip: product.isFavorite == true
                      ? 'Remove from saved'
                      : 'Save product',
                  onPressed: () => _toggleFavorite(context, product),
                  icon: Icon(
                    product.isFavorite == true
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: product.isFavorite == true
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: imageUrl.isEmpty
                    ? _ImageFallback(
                        color: theme.colorScheme.surfaceContainerHighest,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImageFallback(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? 'Untitled product',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$' + _formatPrice(product.price),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description?.trim().isNotEmpty == true
                        ? product.description!
                        : 'No description is available for this product yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Secure account-based shopping with your cart and order history kept together.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Product product,
  ) async {
    final auth = context.read<AuthProvider>();
    if (product.id == null ||
        auth.token == null ||
        auth.userId == null ||
        product.productsRepo == null) {
      return;
    }

    await product.toggleFavoriteStatus(
      product.id!,
      auth.token!,
      auth.userId!,
    );
  }

  void _addToCart(
    BuildContext context,
    Product product,
  ) {
    if (product.id == null ||
        product.price == null ||
        product.title == null) {
      return;
    }

    context.read<CartProvider>().addItem(
          product.id!,
          product.price!,
          product.title!,
        );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(product.title! + ' added to cart'),
        ),
      );
  }

  String _formatPrice(num? price) {
    final value = price?.toDouble() ?? 0;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class _ImageFallback extends StatelessWidget {
  final Color color;

  const _ImageFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
