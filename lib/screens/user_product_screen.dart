import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/provider/products.dart';
import 'package:shop_application/screens/edit_products_screen.dart';
import 'package:shop_application/widgets/app_drawer.dart';

import '../widgets/user_produt_Item.dart';

class UserProductScreen extends StatelessWidget {
  static const routeName = '/userproducts';
  const UserProductScreen({super.key});
  Future<void> _refreshProducts(BuildContext context) async {
    await Provider.of<Products>(context, listen: false)
        .fetchProductsFromJson(true);
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
                      child: Consumer<Products>(
                        builder: (ctx, productdata, _) => ListView.builder(
                            itemCount: productdata.items.length,
                            itemBuilder: (_, i) => UserProductItem(
                                  id: productdata.items[i].id,
                                  imageurl: productdata.items[i].imageUrl,
                                  title: productdata.items[i].title,
                                )),
                      ),
                    ),
                  ),
      ),
    );
  }
}
