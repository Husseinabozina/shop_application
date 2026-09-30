import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';

class ProductItem extends StatelessWidget {
  const ProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = context.watch<Product>();
    final imageUrl = product.imageUrl?.trim() ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            ProductDetailedScreen.routeName,
            arguments: product.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: product.id ?? product.productId ?? product.title ?? '',
                    child: imageUrl.isEmpty
                        ? _ProductImageFallback(
                            color: theme.colorScheme.surfaceContainerHighest,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ProductImageFallback(
                              color:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: product.isFavorite == true
                            ? 'Remove from saved'
                            : 'Save product',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _toggleFavorite(context, product),
                        icon: Icon(
                          product.isFavorite == true
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: product.isFavorite == true
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (product.tracksStock)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _StockBadge(product: product),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.title ?? 'Untitled product',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${_formatPrice(product.price)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: product.isInStock ? 'Add to cart' : 'Sold out',
                    onPressed: product.isInStock
                        ? () => _addToCart(context, product)
                        : null,
                    icon: Icon(
                      product.isInStock
                          ? Icons.add_shopping_cart_rounded
                          : Icons.block_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    if (!product.isInStock ||
        product.id == null ||
        product.price == null ||
        product.title == null) {
      return;
    }

    final added = context.read<CartProvider>().addItem(
          product.id!,
          product.price!,
          product.title!,
          maxQuantity: product.stockQuantity?.toDouble(),
        );

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${product.title!} added to cart'
                : 'Maximum available stock is already in your cart',
          ),
          action: added
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    context
                        .read<CartProvider>()
                        .removeSingleItem(product.id!);
                  },
                )
              : null,
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


class _StockBadge extends StatelessWidget {
  final Product product;

  const _StockBadge({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOut = !product.isInStock;
    final background = isOut
        ? theme.colorScheme.errorContainer
        : product.isLowStock
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surface.withValues(alpha: 0.92);
    final foreground = isOut
        ? theme.colorScheme.onErrorContainer
        : product.isLowStock
            ? theme.colorScheme.onTertiaryContainer
            : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        product.stockLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  final Color color;

  const _ProductImageFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
