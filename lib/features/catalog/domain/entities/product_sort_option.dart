enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
}

extension ProductSortOptionX on ProductSortOption {
  String get label {
    switch (this) {
      case ProductSortOption.featured:
        return 'Featured';
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low to high';
      case ProductSortOption.priceHighToLow:
        return 'Price: High to low';
      case ProductSortOption.nameAZ:
        return 'Name: A–Z';
    }
  }
}
