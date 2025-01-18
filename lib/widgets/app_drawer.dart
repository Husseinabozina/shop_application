import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/provider/auth.dart';
import 'package:shop_application/screens/user_product_screen.dart';

import '../screens/orders_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text("hellow friend"),
            automaticallyImplyLeading: false,
          ),
          ListTile(
            leading: Icon(Icons.shop),
            title: Text("Shop"),
            onTap: (() {
              Navigator.of(context).pushReplacementNamed('/');
            }),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text("Orders"),
            onTap: (() {
              Navigator.of(context)
                  .pushReplacementNamed(OrdersScreen.routeName);
            }),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("manage product"),
            onTap: (() {
              Navigator.of(context)
                  .pushReplacementNamed(UserProductScreen.routeName);
            }),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("log out"),
            onTap: (() {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logOut();
            }),
          ),
        ],
      ),
    );
  }
}
