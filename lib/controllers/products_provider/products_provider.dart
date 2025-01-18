import 'package:flutter/foundation.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/provider/product.dart';

// ProductsRepo Implementation

// ProductsProvider Implementation
class ProductsProvider with ChangeNotifier {
  final ProductsRepo productsRepo;
  final String? token;
  final String? userId;

  ProductsProvider({required this.productsRepo, this.token, this.userId});

  List<Product> _products = [];
  Product? _updatedProduct;

  List<Product> get products => _products;
  Product? get updatedProduct => _updatedProduct;

  String? fetchProductsErrorMessage;
  String? deleteProductSuccessMessage;
  String? deleteProductErrorMessage;
  String? updateProductErrorMessage;
  List<Product> get favitem {
    return _products.where((proditem) => proditem.isFavorite == true).toList();
  }

  Future<void> fetchProducts({bool? filterByUser}) async {
    final result = await productsRepo.fetchProductsFromJson(
      filterByUser: filterByUser,
      userId: userId,
      token: token,
    );
    result.when(
      success: (products) {
        _products = products;
        notifyListeners();
      },
      failure: (exception) {
        fetchProductsErrorMessage = exception.message;
        notifyListeners();
      },
    );
  }

  Product findById(String id) {
    return _products.firstWhere((product) {
      return product.id == id;
    });
  }

  Future<void> deleteProduct(String productId) async {
    final result = await productsRepo.deleteProduct(productId, token!);
    result.when(
      success: (_) {
        deleteProductSuccessMessage = AppStrings.deleteProductSuccessMessage;
        _products?.removeWhere((product) => product.id == productId);
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
        _updatedProduct = updatedProduct;
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
