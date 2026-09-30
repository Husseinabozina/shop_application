import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';

class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final controller = context.watch<RecentlyViewedController>();
    final recentProducts = controller.resolveProducts(products);

    if (recentProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recently viewed',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.clear,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              return _RecentProductCard(
                product: recentProducts[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  final Product product;

  const _RecentProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.imageUrl?.trim() ?? '';
    final productId = product.id ?? product.productId;

    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: productId == null
              ? null
              : () {
                  Navigator.of(context).pushNamed(
                    ProductDetailedScreen.routeName,
                    arguments: productId,
                  );
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${_formatPrice(product.price)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!product.isInStock)
                          Text(
                            'Sold out',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(num? value) {
    final number = value?.toDouble() ?? 0;
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}

class _ImageFallback extends StatelessWidget {
  final Color color;

  const _ImageFallback({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.history_rounded,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
