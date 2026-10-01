import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';

class CartItem extends StatelessWidget {
  final num? price;
  final double? quantity;
  final String? productId;
  final String? title;
  final String? id;

  const CartItem({
    super.key,
    this.price,
    this.id,
    this.quantity,
    this.title,
    this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();
    final products = context.watch<CatalogController>().products;
    final matches = products.where((product) => product.id == productId);
    final matchedProduct = matches.isEmpty ? null : matches.first;
    final imageUrl = matchedProduct?.imageUrl?.trim() ?? '';
    final stockQuantity = matchedProduct?.stockQuantity;
    final itemQuantity = quantity ?? 0;
    final canIncrease =
        stockQuantity == null || itemQuantity < stockQuantity;
    final itemTotal = (price ?? 0) * itemQuantity;

    return Dismissible(
      key: ValueKey(productId ?? id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmRemoval(context),
      onDismissed: (_) {
        if (productId != null) {
          cart.removeItem(productId!);
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 82,
                  height: 82,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${_formatPrice(itemTotal)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QuantityButton(
                          icon: Icons.remove_rounded,
                          onPressed: () {
                            if (productId != null) {
                              cart.removeSingleItem(productId!);
                            }
                          },
                        ),
                        SizedBox(
                          width: 38,
                          child: Text(
                            _formatQuantity(itemQuantity),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add_rounded,
                          onPressed: canIncrease
                              ? () {
                                  if (productId != null &&
                                      price != null &&
                                      title != null) {
                                    cart.addItem(
                                      productId!,
                                      price!,
                                      title!,
                                      maxQuantity:
                                          stockQuantity?.toDouble(),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                    if (!canIncrease) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Maximum available quantity reached',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () async {
                  final confirmed = await _confirmRemoval(context);
                  if (confirmed == true && productId != null) {
                    cart.removeItem(productId!);
                  }
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRemoval(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove item?'),
        content: const Text(
          'This product will be removed from your cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
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
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
