import 'package:shop_application/core/formatters/money.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';
import 'package:shop_application/features/orders/presentation/screens/order_details_screen.dart';

class OrderItem extends StatelessWidget {
  final Order? order;

  const OrderItem({super.key, this.order});

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
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OrderDetailsScreen(order: currentOrder),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orderNumber(currentOrder.id),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                    final compact =
                        constraints.maxWidth < 360 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18;
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 12),
                          _StatusChip(status: currentOrder.status),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        _StatusChip(status: currentOrder.status),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        products.length == 1
                            ? '1 item'
                            : '${products.length} items',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${Money.format(currentOrder.amount ?? 0, currency: currentOrder.currency)}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentOrder.estimatedDeliveryEnd != null &&
                    currentOrder.status.isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Estimated ${DateFormat('MMM d').format(currentOrder.estimatedDeliveryEnd!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Track order',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _orderNumber(String? id) {
    if (id == null || id.isEmpty) {
      return 'Order';
    }

    final suffix = id.length <= 8 ? id : id.substring(id.length - 8);
    return 'Order #${suffix.toUpperCase()}';
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = status == OrderStatus.cancelled;
    final delivered = status == OrderStatus.delivered;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cancelled
            ? theme.colorScheme.errorContainer
            : delivered
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cancelled
              ? theme.colorScheme.onErrorContainer
              : delivered
              ? theme.colorScheme.onTertiaryContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
