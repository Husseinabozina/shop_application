import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/order.dart';
import 'package:shop_application/widgets/cart_item.dart';

import '../provider/cart.dart' show Cart;
import '../widgets/app_drawer.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const routName = "/cartScreen";

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text("Your Card"),
      ),
      body: Column(
        children: [
          Card(
            elevation: 6,
            margin: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Total",
                  style: TextStyle(fontSize: 20),
                ),
                Spacer(),
                Chip(
                  label: Text(
                    "${cart.totalPrice}",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                Orderbutton(cart: cart)
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: cart.Items.length,
                  itemBuilder: (context, i) => CartItem(
                        id: cart.Items.values.toList()[i].id,
                        productId: cart.Items.keys.toList()[i],
                        price: cart.Items.values.toList()[i].price,
                        title: cart.Items.values.toList()[i].title,
                        quantity: cart.Items.values.toList()[i].quantitiy,
                      )))
        ],
      ),
    );
  }
}

class Orderbutton extends StatefulWidget {
  const Orderbutton({
    Key? key,
    required this.cart,
  }) : super(key: key);

  final Cart cart;

  @override
  State<Orderbutton> createState() => _OrderbuttonState();
}

class _OrderbuttonState extends State<Orderbutton> {
  var _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: (widget.cart.totalPrice <= 0 || _isLoading)
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });
                await Provider.of<Orders>(context, listen: false)
                    .addOrderToJson(widget.cart.Items.values.toList(),
                        widget.cart.totalPrice);
                setState(() {
                  _isLoading = false;
                });
                widget.cart.clear();
              },
        child: _isLoading ? CircularProgressIndicator() : Text('order now'));
  }
}
