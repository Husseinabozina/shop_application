import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/provider/product.dart';

import '../provider/products.dart';

class ProductDetailedScreen extends StatelessWidget {
  static const routename = '/ProductDetailed';
  const ProductDetailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String productId = ModalRoute.of(context)!.settings.arguments as String;
    final loadedProduct = Provider.of<ProductsProvider>(context, listen: false)
        .products
        .firstWhere((product) => product.id == productId);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(loadedProduct.title!),
              background: Hero(
                tag: productId,
                child: Image.network(
                  loadedProduct.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(
                height: 10,
              ),
              Text(
                "\$${loadedProduct.price}",
                style: const TextStyle(color: Colors.grey, fontSize: 20),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "${loadedProduct.description}",
                softWrap: true,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 800,
              )
            ]),
          )
        ],
      ),
    );
  }
}
