import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _orderNumber(order.id),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _StatusChip(status: order.status),
                    ],
                  ),
                  if (order.datetime != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      'Placed ' +
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(order.datetime!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.status == OrderStatus.delivered
                                    ? 'Delivered'
                                    : 'Estimated delivery',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _deliveryEstimate(order),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Track order',
            icon: Icons.route_outlined,
            child: _TrackingTimeline(order: order),
          ),
          const SizedBox(height: 14),
          if (order.deliveryAddress != null)
            _SectionCard(
              title: 'Delivery address',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.recipientName != null)
                    Text(
                      order.recipientName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (order.recipientPhone != null) ...[
                    const SizedBox(height: 4),
                    Text(order.recipientPhone!),
                  ],
                  const SizedBox(height: 4),
                  Text(order.deliveryAddress!),
                ],
              ),
            ),
          if (order.deliveryAddress != null) const SizedBox(height: 14),
          _SectionCard(
            title: 'Delivery & payment',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: [
                _InfoRow(
                  label: 'Shipping',
                  value: order.shippingMethodTitle ?? 'Standard delivery',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Payment',
                  value: order.paymentMethodTitle ??
                      _paymentStatusLabel(order.paymentStatus),
                ),
                if (order.paymentStatus != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Payment status',
                    value: _paymentStatusLabel(order.paymentStatus),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Items',
            icon: Icons.shopping_bag_outlined,
            child: _OrderProducts(order: order),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Order total',
            icon: Icons.receipt_long_outlined,
            child: Row(
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$' + _formatPrice(order.amount ?? 0),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orderNumber(String? id) {
    if (id == null || id.isEmpty) {
      return 'Order';
    }

    final suffix = id.length <= 8 ? id : id.substring(id.length - 8);
    return 'Order #' + suffix.toUpperCase();
  }

  String _deliveryEstimate(Order order) {
    final start = order.estimatedDeliveryStart;
    final end = order.estimatedDeliveryEnd;

    if (start != null && end != null) {
      if (_isSameDay(start, end)) {
        return DateFormat('EEE, MMM d').format(end);
      }
      return DateFormat('MMM d').format(start) +
          ' – ' +
          DateFormat('MMM d').format(end);
    }

    if (end != null) {
      return DateFormat('EEE, MMM d').format(end);
    }

    if (order.shippingMinDays != null && order.shippingMaxDays != null) {
      return order.shippingMinDays.toString() +
          '–' +
          order.shippingMaxDays.toString() +
          ' business days';
    }

    return 'Delivery estimate unavailable';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _paymentStatusLabel(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'cash_on_delivery':
        return 'Cash on delivery';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Payment failed';
      case 'refunded':
        return 'Refunded';
      case 'pending':
        return 'Pending';
      default:
        return raw?.replaceAll('_', ' ') ?? 'Not specified';
    }
  }

  static String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}

class _TrackingTimeline extends StatelessWidget {
  final Order order;

  const _TrackingTimeline({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return _CancelledTracking(order: order);
    }

    final currentIndex = order.status.progressIndex;

    return Column(
      children: [
        for (var index = 0; index < orderTrackingSequence.length; index++)
          _TrackingStep(
            status: orderTrackingSequence[index],
            timestamp: order.statusHistory[orderTrackingSequence[index]],
            isCompleted: index < currentIndex,
            isCurrent: index == currentIndex,
            hasLineBelow: index < orderTrackingSequence.length - 1,
          ),
      ],
    );
  }
}

class _TrackingStep extends StatelessWidget {
  final OrderStatus status;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool hasLineBelow;

  const _TrackingStep({
    required this.status,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    required this.hasLineBelow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReached = isCompleted || isCurrent;
    final activeColor = theme.colorScheme.primary;
    final mutedColor = theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isReached ? activeColor : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReached ? activeColor : mutedColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        )
                      : isCurrent
                          ? Center(
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
                if (hasLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isCompleted ? activeColor : mutedColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: hasLineBelow ? 24 : 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isReached
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isReached
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM d • h:mm a').format(timestamp!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else if (isCurrent) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Current status',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledTracking extends StatelessWidget {
  final Order order;

  const _CancelledTracking({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = order.statusHistory[OrderStatus.cancelled];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cancel_outlined,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order cancelled',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 3),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isCancelled
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isCancelled
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderProducts extends StatelessWidget {
  final Order order;

  const _OrderProducts({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final products = order.products ?? const [];
    final theme = Theme.of(context);

    if (products.isEmpty) {
      return Text(
        'Item details are unavailable for this order.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: products.map((product) {
        final quantity = product.quantity ?? 0;
        final total = (product.price ?? 0).toDouble() * quantity;

        return Padding(
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
                _formatQuantity(quantity) + ' × ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '\$' + OrderDetailsScreen._formatPrice(total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
