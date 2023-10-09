import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shop_application/provider/cart.dart';
import 'package:http/http.dart' as http;

class OrderItem with ChangeNotifier {
  final String? id;
  final DateTime? datetime;
  final double? amount;
  final List<CartItem>? products;
  OrderItem({this.id, this.datetime, this.amount, this.products});
}

class Orders with ChangeNotifier {
  List<OrderItem>? _orders = [];
  String? token;
  String? userId;
  Orders(this.token, this.userId, this._orders);
  List<OrderItem>? get orders {
    return _orders;
  }

  Future<void> fetchProductsFromjson() async {
    final url = Uri.parse(
        "https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token");
    final response = await http.get(url);
    List<OrderItem> _loadedorders = [];
    final extractedorder = (json.decode(response.body) as Map<String, dynamic>);
    if (extractedorder == null) {
      return;
    }
    extractedorder.forEach((orderId, orderData) {
      _loadedorders.add(OrderItem(
        id: orderId,
        amount: orderData["amount"],
        datetime: DateTime.parse(orderData['datetime']),
        products: (orderData['products'] as List<dynamic>)
            .map(
              (cartItem) => CartItem(
                  id: cartItem['id'],
                  title: cartItem['title'],
                  price: cartItem['price'],
                  quantitiy: cartItem['quantitiy']),
            )
            .toList(),
      ));
    });
    _orders = _loadedorders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrderToJson(List<CartItem> productList, double total) async {
    final url = Uri.parse(
        'https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token"');
    final timesTamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          'amount': total,
          'datetime': timesTamp.toIso8601String(),
          'products': productList
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantitiy': cp.quantitiy,
                    'price': cp.price
                  })
              .toList()
        }));

    _orders!.insert(
        0,
        OrderItem(
            amount: total,
            datetime: timesTamp,
            id: json.decode(response.body)['name'],
            products: productList));
    notifyListeners();
  }
}
