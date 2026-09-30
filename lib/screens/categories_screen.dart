import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/catalog/domain/entities/catalog_filter.dart';
import 'package:shop_application/features/catalog/domain/entities/product_sort_option.dart';
import 'package:shop_application/features/catalog/presentation/widgets/catalog_filter_sheet.dart';
import 'package:shop_application/widgets/product_grid.dart';
import 'package:shop_application/widgets/store_bottom_navigation.dart';

class CategoriesScreen extends StatefulWidget {
  static const routeName = '/categories';

  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _category;
  String _query = '';
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
        automaticallyImplyLeading: false,
        title: const Text('Categories'),
      ),
      bottomNavigationBar: const StoreBottomNavigation(
        selectedIndex: 1,
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, provider, _) {
          if (_isLoading && provider.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadProducts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Text(
                  'Explore the catalog',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jump into a category or search across the full collection.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search in categories',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) {
                        setState(() => _category = null);
                      },
                    ),
                    ...provider.categories.map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) {
                          setState(() => _category = category);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                      ),
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
                          return PopupMenuItem(
                            value: option,
                            child: Text(option.label),
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
                  ],
                ),
                const SizedBox(height: 14),
                ProductsGrid(
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
  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<CatalogFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CatalogFilterSheet(
        initialFilter: _filter,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _filter = result);
  }

}
