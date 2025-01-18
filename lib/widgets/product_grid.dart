import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';

import '../provider/product.dart';
import '../provider/products.dart';
import 'product_item.dart';

class ProductsGrid extends StatelessWidget {
  bool isfav = false;
  ProductsGrid(this.isfav);
  @override
  Widget build(BuildContext context) {
    final productsData = Provider.of<ProductsProvider>(context, listen: true);
    final products = isfav ? productsData.favitem : productsData.products;
    return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemBuilder: ((context, i) => ChangeNotifierProvider.value(
              value: products[i],
              child: ProductItem(),
            )),
        itemCount: products.length);
  }
}
