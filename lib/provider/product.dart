import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/data/repos/products_repo.dart';

class Product with ChangeNotifier {
  final String? title;
  final String? description;
  final String? productId;
  final String? id;
  final String? imageUrl;
  bool? isFavorite;
  final num? price;

  ProductsRepo? productsRepo;

  Product({
    this.productsRepo,
    this.productId,
    this.price,
    this.description,
    this.id,
    this.imageUrl,
    this.isFavorite = false,
    this.title,
  });

  // fromJson constructor to create a Product object from JSON data
  Product.fromJson(Map<String, dynamic> json, String? productId)
      : title = json['title'],
        description = json['description'],
        id = json['id'],
        this.productId = productId,
        imageUrl = json['imageUrl'],
        isFavorite = json['isFavorite'] ?? false,
        price = json['price'];

  factory Product.updateFromJson(Map<String, dynamic> json) {
    return Product(
      title: json['title'],
      description: json['description'],
      id: json['id'],
      imageUrl: json['imageUrl'],
      isFavorite: json['isFavorite'] ?? false,
      price: json['price'],
    );
  }

  // toJson method to convert a Product object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'id': id,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'price': price,
    };
  }

  // copyWith method to create a new instance with updated fields
  Product copyWith({
    String? title,
    String? description,
    String? productId,
    String? id,
    String? imageUrl,
    bool? isFavorite,
    num? price,
  }) {
    return Product(
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId ?? this.productId,
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      price: price ?? this.price,
    );
  }

  // Future<void> toggleFavoriteStatus(String token, String userId) async {
  //   final url = Uri.parse(
  //       "https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId/$id.json?auth=$token");
  //   bool oldStatus = isFavorite!;

  //   isFavorite = !isFavorite!;
  // notifyListeners();

  //   final response = await http.put(url, body: json.encode(isFavorite));
  //   if (response.statusCode >= 400) {
  //     isFavorite = oldStatus;
  //     notifyListeners();
  //   }

  //   notifyListeners();
  // }
  String? toggleFavoriteStatusErrorMessage;
  Future<void> toggleFavoriteStatus(
      String productId, String token, String userId) async {
    bool oldStatus = isFavorite!;

    isFavorite = !isFavorite!;
    notifyListeners();

    final result = await productsRepo!.toggleFavoriteStatus(
      productId: productId,
      token: token!,
      userId: userId!,
      isFavorite: isFavorite,
    );
    result.when(
      success: (_) {
        notifyListeners();
      },
      failure: (exception) {
        toggleFavoriteStatusErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }
}
