import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/product.dart';

import '../controllers/cart_provider/cart_provider.dart';

class CartItem extends StatelessWidget {
  final num? price;
  final double? quantity;
  final String? productId;
  final String? title;
  final String? id;
  const CartItem(
      {this.price, this.id, this.quantity, this.title, this.productId});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Dismissible(
      confirmDismiss: (direction) {
        return showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Are you sure"),
                  content: const Text(
                      "Do you want to remove the Item from the card?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text("yes")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text("no"))
                  ],
                ));
      },
      onDismissed: (direction) {
        cart.removeItem(productId!);
      },
      key: ValueKey(id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete),
      ),
      direction: DismissDirection.endToStart,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        elevation: 5,
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            child: Text("\$$price"),
          ),
          title: Text("$title"),
          subtitle: Text("Total:\$${price! * quantity!}"),
          trailing: Text("$quantity x"),
        ),
      ),
    );
  }
}
