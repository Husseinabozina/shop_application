// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';

// import 'product.dart';
// import 'package:http/http.dart' as http;

// class Products with ChangeNotifier {
//   String? userId;
//   String? token;
//   Products(this.token, this._items, this.userId);
//   List<Product> _items = [];
//   List<Product> get items {
//     return [..._items];
//   }

//   List<Product> get favitem {
//     return _items.where((proditem) => proditem.isFavorite == true).toList();
//   }

//   Product findById(String id) {
//     return _items.firstWhere((product) {
//       return product.id == id;
//     });
//   }

//   Future<void> updateproduct(String id, Product newprod) async {
//     var index = _items.indexWhere((prod) => prod.id == id);
//     if (index >= 0) {
//       final url = Uri.parse(
//           "https://shopapp-29118-default-rtdb.firebaseio.com/products/${id}.json?auth=$token");
//       await http.patch(url,
//           body: json.encode({
//             'title': newprod.title,
//             'price': newprod.price,
//             'description': newprod.description,
//             'imagurl': newprod.imageUrl,
//           }));
//       _items[index] = newprod;
//     }
//     notifyListeners();
//   }

//   Future<dynamic> addProductToJson(Product product) async {
//     final url = Uri.parse(
//         "https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token");
//     final response = await http.post(url,
//         body: jsonEncode({
//           'title': product.title,
//           'price': product.price,
//           'description': product.description,
//           'imagurl': product.imageUrl,
//           'id': product.id,
//           ' ': userId
//         }));

//     print(jsonDecode(response.body));
//     _items.add(Product(
//         productId: product.id,
//         description: product.description,
//         title: product.title,
//         price: product.price,
//         id: jsonDecode(response.body)['name'],
//         imageUrl: product.imageUrl));
//     // _items.add(value);
//     notifyListeners();
//   }

//   Future<void> deleteProduct(Product prod) async {
//     final int existingProdIndex = items.indexOf(prod);
//     final url = Uri.parse(
//         "https://shopapp-29118-default-rtdb.firebaseio.com/products/${prod.id}.json?auth=$token");
//     final existingprod = items[existingProdIndex];
//     _items.remove(prod);
//     notifyListeners();
//     final response = await http.delete(url);
//     if (response.statusCode >= 400) {
//       _items.insert(existingProdIndex, existingprod);
//       notifyListeners();
//       throw HttpException("could not delete product");
//     }

//     notifyListeners();
//   }

//   Future<void> fetchProductsFromJson([bool filterByUser = false]) async {
//     final String filterString =
//         filterByUser ? '&orderBy="creatorId"&equalTo="$userId"' : '';
//     final url = Uri.parse(
//         'https://shopapp-29118-default-rtdb.firebaseio.com/products.json?auth=$token$filterString');

//     try {
//       final resoponse = await http.get(url);
//       final favoriteResponse = await http.get(Uri.parse(
//           "https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId.json?auth=$token"));
//       final favoriteData = json.decode(favoriteResponse.body);

//       final extractedData = json.decode(resoponse.body) as Map<String, dynamic>;
//       final List<Product> loadedproducts = [];
//       extractedData.forEach((prodId, prodata) {
//         loadedproducts.add(Product(
//             productId: prodId,
//             id: prodId,
//             title: prodata['title'],
//             price: prodata['price'],
//             description: prodata['description'],
//             imageUrl: prodata['imagurl'],
//             isFavorite:
//                 favoriteData == null ? false : favoriteData[prodId] ?? false));
//       });
//       _items = loadedproducts;
//       notifyListeners();
//     } catch (error) {
//       print(error);
//       throw (error);
//     }
//   }
// }
