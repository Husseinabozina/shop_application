import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class Order {
  final String? id;
  final DateTime? datetime;
  final double? amount;
  final List<CartModel>? products;

  Order({
    this.id,
    this.datetime,
    this.amount,
    this.products,
  });

  /// Convert an Order instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datetime': datetime?.toIso8601String(),
      'amount': amount,
      'products': products?.map((product) => product.toJson()).toList(),
    };
  }

  /// Create an Order instance from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String?,
      datetime: json['datetime'] != null
          ? DateTime.parse(json['datetime'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((product) =>
                  CartModel.fromJson(product as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class Orders with ChangeNotifier {
  List<Order>? _orders = [];
  String? token;
  String? userId;
  Orders(this.token, this.userId, this._orders);
  List<Order>? get orders {
    return _orders;
  }
}
//   Future<void> fetchProductsFromjson() async {
//     final url = Uri.parse(
//         "https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token");
//     final response = await http.get(url);
//     List<Order> _loadedorders = [];
//     final extractedorder = (json.decode(response.body) as Map<String, dynamic>);
//     if (extractedorder == null) {
//       return;
//     }
//     extractedorder.forEach((orderId, orderData) {
//       _loadedorders.add(Order(
//         id: orderId,
//         amount: orderData["amount"],
//         datetime: DateTime.parse(orderData['datetime']),
//         products: (orderData['products'] as List<dynamic>)
//             .map(
//               (cartItem) => CartModel(
//                   id: cartItem['id'],
//                   title: cartItem['title'],
//                   price: cartItem['price'],
//                   quantity: cartItem['quantitiy']),
//             )
//             .toList(),
//       ));
//     });
//     _orders = _loadedorders.reversed.toList();
//     notifyListeners();
//   }

//   Future<void> addOrderToJson(List<CartModel> productList, double total) async {
//     final url = Uri.parse(
//         'https://shopapp-29118-default-rtdb.firebaseio.com/order/$userId.json?auth=$token"');
//     final timesTamp = DateTime.now();

//     final response = await http.post(url,
//         body: json.encode({
//           'amount': total,
//           'datetime': timesTamp.toIso8601String(),
//           'products': productList
//               .map((cp) => {
//                     'id': cp.id,
//                     'title': cp.title,
//                     'quantitiy': cp.quantity,
//                     'price': cp.price
//                   })
//               .toList()
//         }));

//     _orders!.insert(
//         0,
//         Order(
//             amount: total,
//             datetime: timesTamp,
//             id: json.decode(response.body)['name'],
//             products: productList));
//     notifyListeners();
//   }
// }
