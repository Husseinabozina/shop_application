import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/provider/products.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/widgets/app_drawer.dart';

import '../widgets/user_produt_Item.dart';

class UserProductScreen extends StatelessWidget {
  static const routeName = '/userproducts';
  const UserProductScreen({super.key});
  Future<void> _refreshProducts(BuildContext context) async {
    await Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text("Your products"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(EditProductScreen.routeName);
              },
              icon: Icon(Icons.add))
        ],
      ),
      body: FutureBuilder(
        future: _refreshProducts(context),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: () => _refreshProducts(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Consumer<ProductsProvider>(
                        builder: (ctx, productdata, _) => ListView.builder(
                            itemCount: productdata.products.length,
                            itemBuilder: (_, i) => UserProductItem(
                                  id: productdata.products[i].id,
                                  imageurl: productdata.products[i].imageUrl,
                                  title: productdata.products[i].title,
                                )),
                      ),
                    ),
                  ),
      ),
    );
  }
}
