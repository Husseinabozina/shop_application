import 'package:flutter/material.dart';
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

  Product.fromJson(
    Map<String, dynamic> json,
    String? firebaseProductId,
  )   : title = json['title'] as String?,
        description = json['description'] as String?,
        id = (json['id'] as String?) ?? firebaseProductId,
        productId = firebaseProductId,
        imageUrl =
            (json['imageUrl'] as String?) ?? (json['imagurl'] as String?),
        isFavorite = json['isFavorite'] as bool? ?? false,
        price = json['price'] as num?;

  factory Product.updateFromJson(
    Map<String, dynamic> json, {
    String? productId,
  }) {
    return Product(
      productId: productId,
      id: (json['id'] as String?) ?? productId,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl:
          (json['imageUrl'] as String?) ?? (json['imagurl'] as String?),
      isFavorite: json['isFavorite'] as bool? ?? false,
      price: json['price'] as num?,
    );
  }

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
      productsRepo: productsRepo,
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId ?? this.productId,
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      price: price ?? this.price,
    );
  }

  String? toggleFavoriteStatusErrorMessage;

  Future<void> toggleFavoriteStatus(
    String productId,
    String token,
    String userId,
  ) async {
    final repository = productsRepo;
    if (repository == null) {
      toggleFavoriteStatusErrorMessage =
          'Favorites are temporarily unavailable.';
      notifyListeners();
      return;
    }

    final oldStatus = isFavorite ?? false;
    isFavorite = !oldStatus;
    notifyListeners();

    final result = await repository.toggleFavoriteStatus(
      productId: productId,
      token: token,
      userId: userId,
      isFavorite: isFavorite,
    );

    result.when(
      success: (_) {
        toggleFavoriteStatusErrorMessage = null;
      },
      failure: (exception) {
        isFavorite = oldStatus;
        toggleFavoriteStatusErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }
}
