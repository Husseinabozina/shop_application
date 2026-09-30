import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/catalog/domain/entities/product_sort_option.dart';
import 'package:shop_application/widgets/product_grid.dart';
import 'package:shop_application/widgets/store_bottom_navigation.dart';

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
  String? _category;
  ProductSortOption _sort = ProductSortOption.featured;

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
      appBar: AppBar(
        title: const Text('MyShop'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const StoreBottomNavigation(
        selectedIndex: 0,
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
                  'Browse by category, sort the collection, save favorites, and build your cart.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _StorefrontHero(
                  onBrowse: () {
                    setState(() {
                      _category = null;
                      _favoritesOnly = false;
                      _sort = ProductSortOption.featured;
                    });
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search products or categories',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                _CategoryRail(
                  categories: productsProvider.categories,
                  selectedCategory: _category,
                  onSelected: (category) {
                    setState(() {
                      _category = category;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilterChip(
                      avatar: const Icon(
                        Icons.favorite_border_rounded,
                        size: 18,
                      ),
                      label: const Text('Saved'),
                      selected: _favoritesOnly,
                      onSelected: (selected) {
                        setState(() => _favoritesOnly = selected);
                      },
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<ProductSortOption>(
                      initialValue: _sort,
                      onSelected: (value) {
                        setState(() => _sort = value);
                      },
                      itemBuilder: (_) {
                        return ProductSortOption.values.map((option) {
                          return PopupMenuItem<ProductSortOption>(
                            value: option,
                            child: Row(
                              children: [
                                if (_sort == option)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                  ),
                                Text(option.label),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Chip(
                        avatar: const Icon(
                          Icons.swap_vert_rounded,
                          size: 18,
                        ),
                        label: Text(_sort.label),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_visibleCount(productsProvider)} items',
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
                  category: _category,
                  sort: _sort,
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
    final normalizedQuery = _query.trim().toLowerCase();
    final selectedCategory = _category?.trim().toLowerCase();

    return source.where((product) {
      if (selectedCategory != null &&
          selectedCategory.isNotEmpty &&
          product.category.trim().toLowerCase() != selectedCategory) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final title = product.title?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      final category = product.category.toLowerCase();

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          category.contains(normalizedQuery);
    }).length;
  }
}


class _StorefrontHero extends StatelessWidget {
  final VoidCallback onBrowse;

  const _StorefrontHero({
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY PERK',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Free standard delivery',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Spend \$500 or more and standard delivery is on us.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Browse products'),
                  style: FilledButton.styleFrom(
                    foregroundColor: scheme.onPrimaryContainer,
                    backgroundColor: scheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              size: 42,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const _CategoryRail({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
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
              onPressed: () async {
                await onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
