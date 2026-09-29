import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_application/provider/order.dart' as ord;

class OrderItem extends StatelessWidget {
  final ord.Order? order;

  const OrderItem({
    super.key,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentOrder = order;
    if (currentOrder == null) {
      return const SizedBox.shrink();
    }

    final products = currentOrder.products ?? const [];
    final date = currentOrder.datetime;
    final formattedDate = date == null
        ? 'Unknown date'
        : DateFormat('MMM d, yyyy • h:mm a').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Card(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            '\$' + _formatPrice(currentOrder.amount ?? 0),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 6),
            if (products.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No item details available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title ?? 'Product',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatQuantity(product.quantity ?? 0) + ' × ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$' + _formatPrice(product.price ?? 0),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
