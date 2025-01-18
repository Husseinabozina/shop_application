import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/screens/edit_products_screen.dart';

import '../provider/products.dart';

class UserProductItem extends StatelessWidget {
  final String? imageurl;
  final String? title;
  final String? id;

  const UserProductItem({this.title, this.imageurl, this.id});

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageurl!),
      ),
      title: Text("$title"),
      trailing: Container(
        width: 100,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(EditProductScreen.routeName, arguments: id);
              },
              icon: Icon(Icons.edit),
              color: Theme.of(context).primaryColor,
            ),
            IconButton(
                onPressed: () async {
                  Product prod =
                      Provider.of<ProductsProvider>(context, listen: false)
                          .findById(id!);
                  try {
                    await Provider.of<ProductsProvider>(context, listen: false)
                        .deleteProduct(prod.id!);
                  } catch (error) {
                    scaffoldMessenger.showSnackBar(SnackBar(
                        content: Text(
                      'Deleting failed!!',
                      textAlign: TextAlign.center,
                    )));
                  }
                },
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                )),
          ],
        ),
      ),
    );
  }
}
