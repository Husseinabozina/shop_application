import 'package:flutter/foundation.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/provider/product.dart';

class ProductsProvider with ChangeNotifier {
  final ProductsRepo productsRepo;
  final String? token;
  final String? userId;

  ProductsProvider({
    required this.productsRepo,
    this.token,
    this.userId,
  });

  List<Product> _products = [];
  Product? _updatedProduct;

  List<Product> get products => _products;
  Product? get updatedProduct => _updatedProduct;

  String? fetchProductsErrorMessage;
  String? deleteProductSuccessMessage;
  String? deleteProductErrorMessage;
  String? updateProductErrorMessage;

  List<Product> get favitem {
    return _products.where((product) => product.isFavorite == true).toList();
  }

  Future<void> fetchProducts({bool? filterByUser}) async {
    final result = await productsRepo.fetchProductsFromJson(
      filterByUser: filterByUser,
      userId: userId,
      token: token,
    );

    result.when(
      success: (products) {
        for (final product in products) {
          product.productsRepo = productsRepo;
        }
        _products = products;
        fetchProductsErrorMessage = null;
        notifyListeners();
      },
      failure: (exception) {
        fetchProductsErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }

  Product findById(String id) {
    return _products.firstWhere((product) => product.id == id);
  }

  Future<void> deleteProduct(String productId) async {
    if (token == null) {
      deleteProductErrorMessage = 'Please sign in again.';
      notifyListeners();
      return;
    }

    final result = await productsRepo.deleteProduct(productId, token!);
    result.when(
      success: (_) {
        deleteProductSuccessMessage = AppStrings.deleteProductSuccessMessage;
        _products.removeWhere((product) => product.id == productId);
        notifyListeners();
      },
      failure: (exception) {
        deleteProductErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }

  Future<void> updateProduct(Product product) async {
    final result = await productsRepo.updateProduct(product, token);
    result.when(
      success: (updatedProduct) {
        updatedProduct.productsRepo = productsRepo;
        _updatedProduct = updatedProduct;

        final index = _products.indexWhere(
          (existingProduct) =>
              existingProduct.id == product.id ||
              existingProduct.productId == product.productId,
        );
        if (index >= 0) {
          _products[index] = updatedProduct;
        }

        notifyListeners();
      },
      failure: (exception) {
        updateProductErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }

  Future<void> addProduct(Product product) async {
    final result = await productsRepo.addProduct(product, token);
    result.when(
      success: (_) {
        notifyListeners();
      },
      failure: (exception) {
        updateProductErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }
}
