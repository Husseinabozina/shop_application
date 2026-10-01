import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog domain imports only Dart and other catalog domain files', () {
    final domain = Directory('lib/features/catalog/domain');
    final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
    for (final file in domain.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        expect(
          uri.startsWith('dart:') ||
              uri.startsWith('package:shop_application/features/catalog/domain/'),
          isTrue,
          reason: '${file.path} must not depend on Flutter, Firebase, or data implementations: $uri',
        );
      }
    }
  });

  test('catalog controllers depend on contracts instead of network implementations', () {
    final controllers = Directory('lib/features/catalog/presentation/controllers');
    for (final file in controllers.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      expect(source, isNot(contains('/data/')), reason: file.path);
      expect(source, isNot(contains('core/firebase/')), reason: file.path);
      expect(source, isNot(contains('core/network/')), reason: file.path);
    }
  });
}
