import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/catalog/domain/entities/catalog_filter.dart';
import 'package:shop_application/features/catalog/domain/entities/product_sort_option.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/widgets/product_item.dart';

class ProductsGrid extends StatelessWidget {
  final bool favoritesOnly;
  final String query;
  final String? category;
  final ProductSortOption sort;
  final CatalogFilter filter;

  const ProductsGrid({
    super.key,
    this.favoritesOnly = false,
    this.query = '',
    this.category,
    this.sort = ProductSortOption.featured,
    this.filter = CatalogFilter.empty,
  });

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final source = favoritesOnly
        ? productsProvider.favitem
        : productsProvider.products;

    final normalizedQuery = query.trim().toLowerCase();
    final selectedCategory = category?.trim().toLowerCase();

    final products = source.where((product) {
      if (selectedCategory != null &&
          selectedCategory.isNotEmpty &&
          product.category.trim().toLowerCase() != selectedCategory) {
        return false;
      }

      if (!filter.matches(product)) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final title = product.title?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      final productCategory = product.category.toLowerCase();

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          productCategory.contains(normalizedQuery);
    }).toList();

    _sortProducts(products);

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
                  ? 'No saved products here'
                  : 'No products found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              favoritesOnly && normalizedQuery.isEmpty
                  ? 'Save products or try another category.'
                  : 'Try another search, category, filter, or sort option.',
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
            childAspectRatio: 0.64,
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

  void _sortProducts(List<Product> products) {
    switch (sort) {
      case ProductSortOption.featured:
        return;
      case ProductSortOption.priceLowToHigh:
        products.sort(
          (a, b) => (a.price ?? 0).compareTo(b.price ?? 0),
        );
        return;
      case ProductSortOption.priceHighToLow:
        products.sort(
          (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
        );
        return;
      case ProductSortOption.nameAZ:
        products.sort(
          (a, b) => (a.title ?? '')
              .toLowerCase()
              .compareTo((b.title ?? '').toLowerCase()),
        );
        return;
    }
  }
}
