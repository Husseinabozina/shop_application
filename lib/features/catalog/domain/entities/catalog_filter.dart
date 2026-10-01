import 'package:shop_application/features/catalog/domain/entities/product.dart';

class CatalogFilter {
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;

  const CatalogFilter({
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  bool get isActive =>
      minPrice != null ||
      maxPrice != null ||
      inStockOnly;

  int get activeCount {
    var count = 0;
    if (minPrice != null || maxPrice != null) {
      count++;
    }
    if (inStockOnly) {
      count++;
    }
    return count;
  }

  bool matches(Product product) {
    final price = product.price?.toDouble();

    if (minPrice != null && (price == null || price < minPrice!)) {
      return false;
    }

    if (maxPrice != null && (price == null || price > maxPrice!)) {
      return false;
    }

    if (inStockOnly && !product.isInStock) {
      return false;
    }

    return true;
  }

  CatalogFilter copyWith({
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return CatalogFilter(
      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }

  static const empty = CatalogFilter();
}
