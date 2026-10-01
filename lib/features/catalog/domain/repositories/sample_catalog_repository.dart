import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';

abstract class SampleCatalogRepository {
  Future<Set<String>> existingProductIds({required String accessToken});

  /// Returns false if another run already created this product. Never updates it.
  Future<bool> createIfAbsent({
    required SampleProduct product,
    required String userId,
    required String accessToken,
  });
}

class SampleCatalogException implements Exception {
  final String message;

  const SampleCatalogException(this.message);

  @override
  String toString() => message;
}
