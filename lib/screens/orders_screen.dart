import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/orders/presentation/controllers/order_controller.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';
import 'package:shop_application/widgets/order_item.dart';
import 'package:shop_application/widgets/store_bottom_navigation.dart';

enum _OrderFilter {
  all,
  active,
  delivered,
  cancelled,
}

class OrdersScreen extends StatefulWidget {
  static const routeName = '/order';

  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Future<void> _ordersFuture;
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    // Loading notifies shared listeners; start after the mounting build finishes.
    _ordersFuture = Future<void>.microtask(() {
      if (mounted) {
        return context.read<OrderController>().fetchOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your orders'),
      ),
      bottomNavigationBar: const StoreBottomNavigation(
        selectedIndex: 3,
      ),
      body: FutureBuilder<void>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Consumer<OrderController>(
            builder: (context, orderProvider, _) {
              if (orderProvider.fetchOrdersErrorMessage != null) {
                return _OrdersErrorState(
                  message: orderProvider.fetchOrdersErrorMessage!,
                  onRetry: orderProvider.fetchOrders,
                );
              }

              if (orderProvider.orders.isEmpty) {
                return const _EmptyOrders();
              }

              final filteredOrders = orderProvider.orders.where((order) {
                switch (_filter) {
                  case _OrderFilter.all:
                    return true;
                  case _OrderFilter.active:
                    return order.status.isActive;
                  case _OrderFilter.delivered:
                    return order.status == OrderStatus.delivered;
                  case _OrderFilter.cancelled:
                    return order.status == OrderStatus.cancelled;
                }
              }).toList();

              return RefreshIndicator(
                onRefresh: orderProvider.fetchOrders,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == _OrderFilter.all,
                              onTap: () => _setFilter(_OrderFilter.all),
                            ),
                            _FilterChip(
                              label: 'Active',
                              selected: _filter == _OrderFilter.active,
                              onTap: () => _setFilter(_OrderFilter.active),
                            ),
                            _FilterChip(
                              label: 'Delivered',
                              selected: _filter == _OrderFilter.delivered,
                              onTap: () => _setFilter(_OrderFilter.delivered),
                            ),
                            _FilterChip(
                              label: 'Cancelled',
                              selected: _filter == _OrderFilter.cancelled,
                              onTap: () => _setFilter(_OrderFilter.cancelled),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filteredOrders.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No orders match this filter.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 24),
                        sliver: SliverList.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return OrderItem(
                              order: filteredOrders[index],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _setFilter(_OrderFilter filter) {
    setState(() {
      _filter = filter;
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

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
              Icons.receipt_long_outlined,
              size: 58,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders you place will appear here with delivery tracking.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _OrdersErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await onRetry();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
