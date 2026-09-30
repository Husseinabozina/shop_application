abstract class RecentlyViewedRepository {
  List<String> loadProductIds();

  Future<void> saveProductIds(List<String> productIds);

  Future<void> clear();
}
