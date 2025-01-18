import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/provider/products.dart';
import 'package:shop_application/screens/cart_screen.dart';
import 'package:shop_application/widgets/badge.dart';

import '../controllers/cart_provider/cart_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/product_grid.dart';

enum filterOptions {
  favourite,
  showall,
}

enum filtercatygories {
  women,
  men,
  children,
  baby,
}

class ProductOverviewScreen extends StatefulWidget {
  const ProductOverviewScreen({super.key});

  @override
  State<ProductOverviewScreen> createState() => _ProductOverviewScreenState();
}

class _ProductOverviewScreenState extends State<ProductOverviewScreen> {
  bool _isloading = false;
  bool isinit = true;

  bool isfavourite = false;

  void didChangeDependencies() {
    if (isinit) {
      setState(() {
        _isloading = true;
      });

      Provider.of<ProductsProvider>(context).fetchProducts().then((_) {
        setState(() {
          _isloading = false;
        });
      });
    }
    isinit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('My Shopapp'),
        actions: [
          PopupMenuButton(
              onSelected: (filterOptions value) {
                setState(() {
                  if (value == filterOptions.favourite) {
                    isfavourite = true;
                  } else {
                    isfavourite = false;
                  }
                });
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                    const PopupMenuItem(
                        child: Text('only Favourite'),
                        value: filterOptions.favourite),
                    const PopupMenuItem(
                      value: filterOptions.showall,
                      child: Text('show All'),
                    ),
                  ]),
          Consumer<CartProvider>(
              builder: ((_, cart, ch) =>
                  BAdge(child: ch, value: cart.cartlengh.toString())),
              child: IconButton(
                icon: Icon(Icons.shopping_basket),
                onPressed: () {
                  Navigator.of(context).pushNamed(CartScreen.routName);
                },
              ))
        ],
      ),
      body: (_isloading)
          ? const Center(child: CircularProgressIndicator())
          : ProductsGrid(isfavourite!),
    );
  }
}
