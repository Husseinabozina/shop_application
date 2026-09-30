import 'package:flutter/material.dart';
import 'package:shop_application/data/repos/products_repo.dart';

class Product with ChangeNotifier {
  final String? title;
  final String? description;
  final String? productId;
  final String? id;
  final String? imageUrl;
  final String category;
  final String? creatorId;
  final int? stockQuantity;
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
    this.category = 'General',
    this.creatorId,
    this.stockQuantity,
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
        category = _normalizedCategory(json['category']),
        creatorId = json['creatorId'] as String?,
        stockQuantity = _parseStockQuantity(json['stockQuantity']),
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
      category: _normalizedCategory(json['category']),
      creatorId: json['creatorId'] as String?,
      stockQuantity: _parseStockQuantity(json['stockQuantity']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      price: json['price'] as num?,
    );
  }

  bool get tracksStock => stockQuantity != null;

  bool get isInStock => stockQuantity == null || stockQuantity! > 0;

  bool get isLowStock =>
      stockQuantity != null && stockQuantity! > 0 && stockQuantity! <= 5;

  String get stockLabel {
    final stock = stockQuantity;
    if (stock == null) {
      return 'In stock';
    }
    if (stock == 0) {
      return 'Sold out';
    }
    if (stock <= 5) {
      return 'Only $stock left';
    }
    return '$stock in stock';
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'creatorId': creatorId,
      'stockQuantity': stockQuantity,
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
    String? category,
    String? creatorId,
    int? stockQuantity,
    bool clearStock = false,
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
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      stockQuantity: clearStock
          ? null
          : stockQuantity ?? this.stockQuantity,
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

  static String _normalizedCategory(Object? raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? 'General' : value;
  }

  static int? _parseStockQuantity(Object? raw) {
    if (raw == null) {
      return null;
    }

    final value = raw is num
        ? raw.toInt()
        : int.tryParse(raw.toString());

    if (value == null) {
      return null;
    }

    return value < 0 ? 0 : value;
  }
}
