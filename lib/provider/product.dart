import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String? title;
  final String? description;
  final String? id;
  final String? imageUrl;
  bool? isFavorite;
  final num? price;
  Product({
    required this.price,
    required this.description,
    required this.id,
    required this.imageUrl,
    this.isFavorite = false,
    required this.title,
  });

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final url = Uri.parse(
        "https://shopapp-29118-default-rtdb.firebaseio.com/userfavorite/$userId/$id.json?auth=$token");
    bool oldStatus = isFavorite!;

    isFavorite = !isFavorite!;
    notifyListeners();

    final response = await http.put(url, body: json.encode(isFavorite));
    if (response.statusCode >= 400) {
      isFavorite = oldStatus;
      notifyListeners();
    }

    notifyListeners();
  }
}
