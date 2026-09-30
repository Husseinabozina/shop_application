import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';

class RecentlyViewedRepositoryImpl implements RecentlyViewedRepository {
  static const _cachePrefix = 'recently_viewed_product_ids';

  @override
  List<String> loadProductIds(String scope) {
    return CacheHelper.getStringList(_key(scope));
  }

  @override
  Future<void> saveProductIds(
    String scope,
    List<String> productIds,
  ) async {
    await CacheHelper.setStringList(
      _key(scope),
      productIds,
    );
  }

  @override
  Future<void> clear(String scope) async {
    await CacheHelper.remove(_key(scope));
  }

  String _key(String scope) {
    return '${_cachePrefix}_$scope';
  }
}
