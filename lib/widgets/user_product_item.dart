import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/screens/edit_products_screen.dart';

class UserProductItem extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? id;
  final String category;
  final num? price;
  final int? stockQuantity;

  const UserProductItem({
    super.key,
    this.title,
    this.imageUrl,
    this.id,
    this.category = 'General',
    this.price,
    this.stockQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 76,
                height: 76,
                child: _ProductThumbnail(imageUrl: imageUrl),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title ?? 'Untitled product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${_formatPrice(price)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stockLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: stockQuantity == 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _edit(context);
                } else if (value == 'delete') {
                  _delete(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    final productId = id;
    if (productId == null) {
      return;
    }

    Navigator.of(context).pushNamed(
      EditProductScreen.routeName,
      arguments: productId,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final productId = id;
    if (productId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Remove ${title ?? 'this product'} from the storefront?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final provider = context.read<CatalogController>();
    await provider.deleteProduct(productId);

    if (!context.mounted) {
      return;
    }

    final error = provider.deleteProductErrorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  String get _stockLabel {
    final stock = stockQuantity;
    if (stock == null) {
      return 'Stock not tracked';
    }
    if (stock == 0) {
      return 'Sold out';
    }
    return '$stock in stock';
  }
  String _formatPrice(num? value) {
    final number = value?.toDouble() ?? 0;
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _ProductThumbnail({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );

    if (url.isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
