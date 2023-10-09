import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/screens/product_detailed_screen.dart';

import '../provider/auth.dart';
import '../provider/cart.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);
    final product = Provider.of<Product>(context, listen: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            ProductDetailedScreen.routename,
            arguments: product.id,
          );
        },
        child: GridTile(
          footer: GridTileBar(
            backgroundColor: Colors.black54,
            title: Text(
              "${product.title}",
              textAlign: TextAlign.center,
            ),
            leading: Consumer<Product>(
              builder: (ctx, product, _) => IconButton(
                onPressed: (() {
                  product.toggleFavoriteStatus(
                      Provider.of<Auth>(context, listen: false).token!,
                      Provider.of<Auth>(context, listen: false).userId!);
                }),
                icon: Icon(
                  product.isFavorite! ? Icons.favorite : Icons.favorite_border,
                  color: Theme.of(context).errorColor,
                ),
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                cart.addItem(product.id!, product.price!, product.title!);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    action: SnackBarAction(
                      label: "undo",
                      onPressed: () {
                        cart.removeSingleItem(product.id!);
                      },
                    ),
                    content: const Text("you added a product to the cart!!")));
              },
              icon: const Icon(
                Icons.shopping_cart,
                color: Colors.redAccent,
              ),
            ),
          ),
          child: Hero(
            tag: product.id!,
            child: FadeInImage(
              placeholder:
                  const AssetImage('assets/images/placeholderimage.png'),
              image: NetworkImage(product.imageUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
