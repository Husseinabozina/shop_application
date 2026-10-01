import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';

class SampleCatalogRepositoryImpl implements SampleCatalogRepository {
  final FirebaseRestClient database;

  const SampleCatalogRepositoryImpl({required this.database});

  @override
  Future<Set<String>> existingProductIds({required String accessToken}) async {
    final response = await database.get(
      path: 'products',
      authToken: accessToken,
      query: const {'shallow': 'true'},
    );
    _checkStatus(response.statusCode);
    final data = jsonDecode(response.body);
    if (data == null) {
      return {};
    }
    if (data is! Map<String, dynamic>) {
      throw const SampleCatalogException(
        'Could not read the catalog. Try again.',
      );
    }
    return data.keys.toSet();
  }

  @override
  Future<bool> createIfAbsent({
    required SampleProduct product,
    required String userId,
    required String accessToken,
  }) async {
    final response = await database.put(
      path: 'products/${product.id}',
      authToken: accessToken,
      // A server-side condition also protects against simultaneous runs.
      ifMatch: 'null_etag',
      data: {
        'id': product.id,
        'title': product.title,
        'description': product.description,
        'category': product.category,
        'imageUrl': product.imageUrl,
        'imageUrls': [product.imageUrl],
        'price': product.price,
        'stockQuantity': product.stockQuantity,
        'creatorId': userId,
      },
    );
    if (response.statusCode == 412) {
      return false;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Another account may have won creation before ownership rules ran.
      final current = await database.get(
        path: 'products/${product.id}',
        authToken: accessToken,
      );
      if (current.statusCode == 200 && jsonDecode(current.body) is Map) {
        return false;
      }
    }
    _checkStatus(response.statusCode);
    return true;
  }

  void _checkStatus(int status) {
    if (status == 401 || status == 403) {
      throw const SampleCatalogException(
        'Please sign in again to add products.',
      );
    }
    if (status < 200 || status >= 300) {
      throw const SampleCatalogException(
        'Could not add the collection. Try again to complete the missing items.',
      );
    }
  }
}
