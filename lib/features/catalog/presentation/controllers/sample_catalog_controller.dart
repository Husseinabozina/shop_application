import 'package:flutter/foundation.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';
import 'package:shop_application/features/catalog/domain/usecases/add_sample_catalog.dart';

class SampleCatalogController extends ChangeNotifier {
  final AddSampleCatalog addSampleCatalog;
  bool _isAdding = false;
  bool _disposed = false;
  String? _message;
  bool _hasError = false;

  SampleCatalogController({required this.addSampleCatalog});

  bool get isAdding => _isAdding;
  String? get message => _message;
  bool get hasError => _hasError;

  Future<void> add({
    required String userId,
    required String accessToken,
  }) async {
    if (_isAdding || _disposed) {
      return;
    }
    _isAdding = true;
    _message = null;
    _hasError = false;
    notifyListeners();
    try {
      final count = await addSampleCatalog(
        userId: userId,
        accessToken: accessToken,
      );
      _message = count == 0
          ? 'The sample collection is already available.'
          : '$count sample products added. Your collection is ready.';
    } on SampleCatalogException catch (error) {
      _message = error.message;
      _hasError = true;
    } catch (_) {
      _message =
          'Check your connection and try again to finish the collection.';
      _hasError = true;
    } finally {
      _isAdding = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
