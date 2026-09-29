import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/order_provider/order_provider.dart';
import 'package:shop_application/widgets/orderItem.dart';

import '../widgets/app_drawer.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/order';

  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Future<void> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = Provider.of<OrderProvider>(
      context,
      listen: false,
    ).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Your orders'),
      ),
      body: FutureBuilder<void>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              if (orderProvider.fetchOrdersErrorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      orderProvider.fetchOrdersErrorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (orderProvider.orders.isEmpty) {
                return const Center(
                  child: Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: orderProvider.orders.length,
                itemBuilder: (context, index) => OrderItem(
                  order: orderProvider.orders[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
