import 'package:flutter/material.dart';
import 'package:shop_application/widgets/brand_mark.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/features/catalog/domain/entities/catalog_filter.dart';
import 'package:shop_application/features/catalog/domain/entities/product_sort_option.dart';
import 'package:shop_application/features/catalog/presentation/widgets/catalog_filter_sheet.dart';
import 'package:shop_application/features/catalog/presentation/widgets/recently_viewed_section.dart';
import 'package:shop_application/features/catalog/presentation/screens/sample_catalog_screen.dart';
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
  CatalogFilter _filter = CatalogFilter.empty;

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

    await context.read<CatalogController>().fetchProducts();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [BrandMark(size: 32), SizedBox(width: 10), Text('MyShop')],
        ),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const StoreBottomNavigation(selectedIndex: 0),
      body: Consumer<CatalogController>(
        builder: (context, productsProvider, _) {
          if (_isLoading && productsProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productsProvider.fetchProductsErrorMessage != null &&
              productsProvider.products.isEmpty) {
            return _ErrorState(
              message: productsProvider.fetchProductsErrorMessage!,
              onRetry: _loadProducts,
            );
          }

          if (productsProvider.products.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.storefront_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your storefront starts here',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore a sample collection with photos, prices, and stock, '
                    'or add your own products from Account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(SampleCatalogScreen.routeName),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Explore sample collection'),
                  ),
                ],
              ),
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
                  'Thoughtful picks for your home and your everyday.',
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
                      _filter = CatalogFilter.empty;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const RecentlyViewedSection(),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                    ActionChip(
                      avatar: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _filter.activeCount == 0
                            ? 'Filters'
                            : 'Filters (${_filter.activeCount})',
                      ),
                      onPressed: _openFilters,
                    ),
                    PopupMenuButton<ProductSortOption>(
                      initialValue: _sort,
                      onSelected: (value) {
                        setState(() => _sort = value);
                      },
                      itemBuilder: (_) {
                        return ProductSortOption.values.map((option) {
                          return PopupMenuItem<ProductSortOption>(
                            value: option,
                            child: Text(option.label),
                          );
                        }).toList();
                      },
                      child: Chip(
                        avatar: const Icon(Icons.swap_vert_rounded, size: 18),
                        label: Text(_sort.label),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_visibleCount(productsProvider)} items',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ProductsGrid(
                  favoritesOnly: _favoritesOnly,
                  query: _query,
                  category: _category,
                  sort: _sort,
                  filter: _filter,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _visibleCount(CatalogController provider) {
    final source = _favoritesOnly
        ? provider.favoriteProducts
        : provider.products;
    final normalizedQuery = _query.trim().toLowerCase();
    final selectedCategory = _category?.trim().toLowerCase();

    return source.where((product) {
      if (selectedCategory != null &&
          selectedCategory.isNotEmpty &&
          product.category.trim().toLowerCase() != selectedCategory) {
        return false;
      }

      if (!_filter.matches(product)) {
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

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<CatalogFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CatalogFilterSheet(initialFilter: _filter),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _filter = result);
  }
}

class _StorefrontHero extends StatelessWidget {
  final VoidCallback onBrowse;

  const _StorefrontHero({required this.onBrowse});

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
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
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
                  'Spend 500 EGP or more and standard delivery is on us.',
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
          if (MediaQuery.sizeOf(context).width >= 500) ...[
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
      height: MediaQuery.textScalerOf(context).scale(16) + 32,
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

  const _ErrorState({required this.message, required this.onRetry});

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
