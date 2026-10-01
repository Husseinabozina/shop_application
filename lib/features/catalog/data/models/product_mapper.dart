import 'package:shop_application/features/catalog/domain/entities/product.dart';

/// Owns compatibility with existing Firebase product records.
class ProductMapper {
  static Product fromJson(Map<String, dynamic> json, String productId) {
    final rawCategory = json['category']?.toString().trim();
    final rawStock = json['stockQuantity'];
    final stock = rawStock is num
        ? rawStock.toInt()
        : int.tryParse(rawStock?.toString() ?? '');
    final rawImages = json['imageUrls'];

    return Product(
      // The record key is authoritative for reads, writes, and navigation.
      id: productId,
      productId: productId,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: (json['imageUrl'] as String?) ?? (json['imagurl'] as String?),
      imageUrls: rawImages is List
          ? rawImages.whereType<String>().toList()
          : const [],
      category: rawCategory == null || rawCategory.isEmpty
          ? 'General'
          : rawCategory,
      creatorId: json['creatorId'] as String?,
      stockQuantity: stock == null ? null : (stock < 0 ? 0 : stock),
      isFavorite: json['isFavorite'] == true,
      price: json['price'] as num?,
    );
  }

  static Map<String, dynamic> toJson(Product product) => {
    'title': product.title,
    'description': product.description,
    'id': product.id,
    'imageUrl': product.imageUrl,
    'imageUrls': product.imageUrls,
    'category': product.category,
    'creatorId': product.creatorId,
    'stockQuantity': product.stockQuantity,
    'price': product.price,
    // Favorite state belongs to the user's private collection, not a listing.
  };
}
