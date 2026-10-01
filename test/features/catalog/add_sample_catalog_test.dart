import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/catalog/domain/entities/sample_product.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';
import 'package:shop_application/features/catalog/domain/usecases/add_sample_catalog.dart';
import 'package:shop_application/features/catalog/presentation/controllers/sample_catalog_controller.dart';

class _MemoryCatalog implements SampleCatalogRepository {
  final records = <String, String>{};
  int writes = 0;
  int? failAt;
  Completer<void>? gate;

  @override
  Future<Set<String>> existingProductIds({required String accessToken}) async {
    await gate?.future;
    return records.keys.toSet();
  }

  @override
  Future<bool> createIfAbsent({
    required SampleProduct product,
    required String userId,
    required String accessToken,
  }) async {
    if (writes == failAt) {
      throw const SampleCatalogException('Connection interrupted.');
    }
    if (records.containsKey(product.id)) return false;
    writes++;
    records[product.id] = userId;
    return true;
  }
}

void main() {
  test(
    'fills missing samples without touching existing listings or owners',
    () async {
      final repository = _MemoryCatalog();
      repository.records[sampleCatalog.first.id] = 'original-owner';
      repository.records['real-product'] = 'seller';
      final added = await AddSampleCatalog(repository)(
        userId: 'owner',
        accessToken: 'token',
      );
      expect(added, sampleCatalog.length - 1);
      expect(repository.records[sampleCatalog.first.id], 'original-owner');
      expect(repository.records['real-product'], 'seller');
      expect(repository.records[sampleCatalog.last.id], 'owner');
      expect(
        await AddSampleCatalog(repository)(
          userId: 'another-user',
          accessToken: 'token',
        ),
        0,
      );
      expect(repository.writes, 7);
    },
  );

  test('interrupted run resumes only the remaining items', () async {
    final repository = _MemoryCatalog()..failAt = 3;
    final useCase = AddSampleCatalog(repository);
    await expectLater(
      useCase(userId: 'owner', accessToken: 'token'),
      throwsA(isA<SampleCatalogException>()),
    );
    expect(repository.records.length, 3);
    repository.failAt = null;
    expect(await useCase(userId: 'owner', accessToken: 'token'), 5);
    expect(repository.records.length, 8);
  });

  test('requires a session before reading or writing', () async {
    final repository = _MemoryCatalog();
    await expectLater(
      AddSampleCatalog(repository)(userId: '', accessToken: ''),
      throwsA(isA<SampleCatalogException>()),
    );
    expect(repository.records, isEmpty);
    expect(repository.writes, 0);
  });

  test(
    'controller ignores double taps and safely completes after disposal',
    () async {
      final repository = _MemoryCatalog()..gate = Completer<void>();
      final controller = SampleCatalogController(
        addSampleCatalog: AddSampleCatalog(repository),
      );
      final first = controller.add(userId: 'owner', accessToken: 'token');
      await controller.add(userId: 'owner', accessToken: 'token');
      expect(controller.isAdding, isTrue);
      controller.dispose();
      repository.gate!.complete();
      await first;
      expect(repository.writes, 8);
    },
  );
}
