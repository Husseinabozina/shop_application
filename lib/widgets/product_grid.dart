import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';

import '../provider/product.dart';
import 'product_item.dart';

class ProductsGrid extends StatelessWidget {
  final bool favoritesOnly;
  final String query;

  const ProductsGrid({
    super.key,
    this.favoritesOnly = false,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final source = favoritesOnly
        ? productsProvider.favitem
        : productsProvider.products;

    final normalizedQuery = query.trim().toLowerCase();
    final products = source.where((product) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      final title = product.title?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery);
    }).toList();

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Icon(
              favoritesOnly
                  ? Icons.favorite_border_rounded
                  : Icons.search_off_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              favoritesOnly && normalizedQuery.isEmpty
                  ? 'No saved products yet'
                  : 'No products match your search',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              favoritesOnly && normalizedQuery.isEmpty
                  ? 'Tap the heart on a product to keep it here.'
                  : 'Try a different product name or keyword.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 4
            : width >= 680
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.66,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ChangeNotifierProvider<Product>.value(
              value: products[index],
              child: const ProductItem(),
            );
          },
        );
      },
    );
  }
}
