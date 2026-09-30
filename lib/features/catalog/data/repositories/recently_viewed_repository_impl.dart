import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';

class RecentlyViewedRepositoryImpl implements RecentlyViewedRepository {
  static const _cacheKey = 'recently_viewed_product_ids';

  @override
  List<String> loadProductIds() {
    return CacheHelper.getStringList(_cacheKey);
  }

  @override
  Future<void> saveProductIds(List<String> productIds) async {
    await CacheHelper.setStringList(
      _cacheKey,
      productIds,
    );
  }

  @override
  Future<void> clear() async {
    await CacheHelper.remove(_cacheKey);
  }
}
