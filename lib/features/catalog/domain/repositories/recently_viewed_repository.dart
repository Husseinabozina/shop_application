abstract class RecentlyViewedRepository {
  List<String> loadProductIds(String scope);

  Future<void> saveProductIds(
    String scope,
    List<String> productIds,
  );

  Future<void> clear(String scope);
}
