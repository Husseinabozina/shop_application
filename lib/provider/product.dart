import 'package:flutter/material.dart';
import 'package:shop_application/data/repos/products_repo.dart';

class Product with ChangeNotifier {
  final String? title;
  final String? description;
  final String? productId;
  final String? id;
  final String? imageUrl;
  final List<String> imageUrls;
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
    String? imageUrl,
    List<String>? imageUrls,
    this.category = 'General',
    this.creatorId,
    this.stockQuantity,
    this.isFavorite = false,
    this.title,
  })  : imageUrls = _normalizeImageUrls(
          imageUrls,
          imageUrl,
        ),
        imageUrl = _resolvePrimaryImage(
          imageUrls,
          imageUrl,
        );

  factory Product.fromJson(
    Map<String, dynamic> json,
    String? firebaseProductId,
  ) {
    final images = _parseImageUrls(json);

    return Product(
      title: json['title'] as String?,
      description: json['description'] as String?,
      id: (json['id'] as String?) ?? firebaseProductId,
      productId: firebaseProductId,
      imageUrl: images.isEmpty ? null : images.first,
      imageUrls: images,
      category: _normalizedCategory(json['category']),
      creatorId: json['creatorId'] as String?,
      stockQuantity: _parseStockQuantity(json['stockQuantity']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      price: json['price'] as num?,
    );
  }

  factory Product.updateFromJson(
    Map<String, dynamic> json, {
    String? productId,
  }) {
    final images = _parseImageUrls(json);

    return Product(
      productId: productId,
      id: (json['id'] as String?) ?? productId,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: images.isEmpty ? null : images.first,
      imageUrls: images,
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
      'imageUrls': imageUrls,
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
    List<String>? imageUrls,
    String? category,
    String? creatorId,
    int? stockQuantity,
    bool clearStock = false,
    bool? isFavorite,
    num? price,
  }) {
    final nextImages = imageUrls ??
        (imageUrl != null ? <String>[imageUrl] : this.imageUrls);

    return Product(
      productsRepo: productsRepo,
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId ?? this.productId,
      id: id ?? this.id,
      imageUrl: nextImages.isEmpty
          ? imageUrl ?? this.imageUrl
          : nextImages.first,
      imageUrls: nextImages,
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

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final primary =
        (json['imageUrl'] as String?) ?? (json['imagurl'] as String?);
    final raw = json['imageUrls'];

    final images = <String>[];
    if (primary != null && primary.trim().isNotEmpty) {
      images.add(primary.trim());
    }

    if (raw is List) {
      for (final value in raw) {
        final image = value?.toString().trim();
        if (image != null &&
            image.isNotEmpty &&
            !images.contains(image)) {
          images.add(image);
        }
      }
    }

    return List.unmodifiable(images);
  }

  static List<String> _normalizeImageUrls(
    List<String>? imageUrls,
    String? imageUrl,
  ) {
    final images = <String>[];

    if (imageUrls != null) {
      for (final value in imageUrls) {
        final image = value.trim();
        if (image.isNotEmpty && !images.contains(image)) {
          images.add(image);
        }
      }
    }

    final primary = imageUrl?.trim();
    if (primary != null &&
        primary.isNotEmpty &&
        !images.contains(primary)) {
      images.insert(0, primary);
    }

    return List.unmodifiable(images);
  }

  static String? _resolvePrimaryImage(
    List<String>? imageUrls,
    String? imageUrl,
  ) {
    final normalized = _normalizeImageUrls(
      imageUrls,
      imageUrl,
    );
    return normalized.isEmpty ? null : normalized.first;
  }
}
