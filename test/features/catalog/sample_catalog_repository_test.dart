import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/features/catalog/data/repositories/sample_catalog_repository_impl.dart';
import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';

class _Database implements FirebaseRestClient {
  int writeStatus = 200;
  String readBody = 'null';
  int readStatus = 200;
  String? path;
  String? token;
  String? condition;
  Object? body;

  @override
  Future<http.Response> get({
    required String path,
    String? authToken,
    Map<String, dynamic>? query,
  }) async {
    return http.Response(readBody, readStatus);
  }

  @override
  Future<http.Response> put({
    required String path,
    required Object data,
    String? authToken,
    String? ifMatch,
  }) async {
    this.path = path;
    token = authToken;
    condition = ifMatch;
    body = data;
    return http.Response('{}', writeStatus);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected database operation');
}

void main() {
  test('creates a valid owned listing only when its path is empty', () async {
    final database = _Database();
    final repository = SampleCatalogRepositoryImpl(database: database);
    expect(
      await repository.createIfAbsent(
        product: sampleCatalog.first,
        userId: 'owner',
        accessToken: 'token',
      ),
      isTrue,
    );
    expect(database.path, 'products/${sampleCatalog.first.id}');
    expect(database.condition, 'null_etag');
    expect(database.token, 'token');
    expect((database.body as Map)['creatorId'], 'owner');
    expect((database.body as Map)['imageUrls'], [sampleCatalog.first.imageUrl]);
    expect((database.body as Map)['stockQuantity'], 12);
  });

  test('a precondition conflict preserves the existing listing', () async {
    final database = _Database()..writeStatus = 412;
    expect(
      await SampleCatalogRepositoryImpl(database: database).createIfAbsent(
        product: sampleCatalog.first,
        userId: 'owner',
        accessToken: 'token',
      ),
      isFalse,
    );
  });

  test(
    'another owner winning the race is skipped, expired auth is an error',
    () async {
      final database = _Database()
        ..writeStatus = 401
        ..readBody = '{"creatorId":"other"}';
      final repository = SampleCatalogRepositoryImpl(database: database);
      expect(
        await repository.createIfAbsent(
          product: sampleCatalog.first,
          userId: 'owner',
          accessToken: 'token',
        ),
        isFalse,
      );
      database.readStatus = 401;
      await expectLater(
        repository.createIfAbsent(
          product: sampleCatalog.first,
          userId: 'owner',
          accessToken: 'token',
        ),
        throwsA(isA<SampleCatalogException>()),
      );
    },
  );

  test('a server failure stays actionable for a later retry', () async {
    final database = _Database()..writeStatus = 503;
    await expectLater(
      SampleCatalogRepositoryImpl(database: database).createIfAbsent(
        product: sampleCatalog.first,
        userId: 'owner',
        accessToken: 'token',
      ),
      throwsA(isA<SampleCatalogException>()),
    );
  });
}
