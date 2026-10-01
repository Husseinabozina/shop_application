import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';

/// Adds only missing fixtures. Retrying preserves edits, stock, and ownership.
class AddSampleCatalog {
  final SampleCatalogRepository repository;

  const AddSampleCatalog(this.repository);

  Future<int> call({
    required String userId,
    required String accessToken,
  }) async {
    if (userId.trim().isEmpty || accessToken.trim().isEmpty) {
      throw const SampleCatalogException('Please sign in again.');
    }

    final existing = await repository.existingProductIds(
      accessToken: accessToken,
    );
    var created = 0;
    for (final product in sampleCatalog) {
      if (existing.contains(product.id)) {
        continue;
      }
      if (await repository.createIfAbsent(
        product: product,
        userId: userId,
        accessToken: accessToken,
      )) {
        created++;
      }
    }
    return created;
  }
}
