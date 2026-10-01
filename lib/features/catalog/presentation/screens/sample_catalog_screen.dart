import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/features/catalog/presentation/controllers/sample_catalog_controller.dart';

class SampleCatalogScreen extends StatefulWidget {
  static const routeName = '/sample-collection';

  const SampleCatalogScreen({super.key});

  @override
  State<SampleCatalogScreen> createState() => _SampleCatalogScreenState();
}

class _SampleCatalogScreenState extends State<SampleCatalogScreen> {
  bool _isRefreshing = false;

  Future<void> _addCollection() async {
    final controller = context.read<SampleCatalogController>();
    if (controller.isAdding || _isRefreshing) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final products = context.read<ProductsProvider>();
    await controller.add(
      userId: auth.userId ?? '',
      accessToken: auth.token ?? '',
    );
    if (!mounted) {
      return;
    }
    setState(() => _isRefreshing = true);
    // Refresh even after partial failure so successful items are usable.
    await products.fetchProducts();
    await products.fetchProducts(filterByUser: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<SampleCatalogController>();
    final busy = controller.isAdding || _isRefreshing;

    return Scaffold(
      appBar: AppBar(title: const Text('Sample collection')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Text(
            'A storefront ready to explore',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add eight sample products to try browsing, saving favorites, '
            'and cash-on-delivery checkout. Existing products stay as they are.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'These are demonstration listings with sample prices. '
            'You can edit or remove the products you add in Manage products.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('4 categories')),
              Chip(label: Text('Low-stock examples')),
              Chip(label: Text('Sold-out example')),
            ],
          ),
          const SizedBox(height: 16),
          ...sampleCatalog.map(
            (product) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} • \$${product.price.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.stockQuantity == 0
                          ? 'Sold out'
                          : '${product.stockQuantity} in stock',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.message != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.message!,
                  key: const ValueKey('sample-catalog-message'),
                  style: TextStyle(
                    color: controller.hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            if (controller.message != null &&
                !controller.hasError &&
                !busy) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse collection'),
              ),
            ],
            FilledButton.icon(
              onPressed: busy ? null : _addCollection,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                busy ? 'Adding collection…' : 'Add sample collection',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
