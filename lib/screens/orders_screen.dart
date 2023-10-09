import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/cart.dart';
import 'package:shop_application/provider/order.dart' show Orders;

import '../widgets/app_drawer.dart';
import '../widgets/orderItem.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/order';
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future? _orderFuture;
  Future _obtainedOrdersFuture() {
    return Provider.of<Orders>(context, listen: false).fetchProductsFromjson();
  }

  bool isinit = false;
  @override
  void initState() {
    _orderFuture = _obtainedOrdersFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(title: Text("your orders")),
      body: FutureBuilder(
          future: _orderFuture,
          builder: (context, snapshotdata) {
            if (snapshotdata.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshotdata.error != null) {
              return Center(
                  child: Text(
                'there is an error',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ));
            } else {
              return Consumer<Orders>(
                builder: (context, orderpro, child) => ListView.builder(
                    itemCount: orderpro.orders!.length,
                    itemBuilder: ((context, index) => OrderItem(
                          order: orderpro.orders![index],
                        ))),
              );
            }
          }),
    );
  }
}
