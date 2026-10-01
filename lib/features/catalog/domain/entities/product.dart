class Product {
  final String? title;
  final String? description;
  final String? productId;
  final String? id;
  final String? imageUrl;
  final List<String> imageUrls;
  final String category;
  final String? creatorId;
  final int? stockQuantity;
  final bool isFavorite;
  final num? price;

  Product({
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

  static List<String> _normalizeImageUrls(
    List<String>? imageUrls,
    String? imageUrl,
  ) {
    final images = <String>[];

    final primary = imageUrl?.trim();
    if (primary != null && primary.isNotEmpty) {
      images.add(primary);
    }

    if (imageUrls != null) {
      for (final value in imageUrls) {
        final image = value.trim();
        if (image.isNotEmpty && !images.contains(image)) {
          images.add(image);
        }
      }
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
