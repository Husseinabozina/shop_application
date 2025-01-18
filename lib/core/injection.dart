import 'package:get_it/get_it.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/order_provider/order_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/data/services/order_services.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/provider/product.dart';

GetIt getIt = GetIt.instance;

void setup() {
  getIt.registerLazySingleton<Api>(() => ApiImpl());

  getIt.registerLazySingleton<ProductService>(
    () => ProductServiceImpl(
      api: getIt<Api>(),
    ),
  );
  getIt.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(
      getIt.get<ProductService>(),
    ),
  );
  getIt.registerLazySingleton<ProductsProvider>(
    () => ProductsProvider(
      productsRepo: getIt.get<ProductsRepo>(),
    ),
  );

  getIt.registerLazySingleton<ProductService>(
    () => ProductServiceImpl(
      api: getIt.get<Api>(),
    ),
  );

  getIt.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(
      getIt.get<ProductService>(),
    ),
  );

  getIt.registerLazySingleton<ProductsProvider>(
    () => ProductsProvider(
      productsRepo: getIt.get<ProductsRepo>(),
    ),
  );

  getIt.registerLazySingleton<OrderServices>(
    () => OrderServicesImpl(
      getIt.get<Api>(),
    ),
  );
  getIt.registerLazySingleton<OrderRepo>(() => OrderRepoImpl(
        orderServices: getIt.get<OrderServices>(),
      ));
  getIt.registerLazySingleton<OrderProvider>(() => OrderProvider(
        orderRepo: getIt.get<OrderRepo>(),
      ));

  getIt.registerLazySingleton<CartProvider>(
    () => CartProvider(),
  );

  getIt.registerFactory<Product>(
    () => Product(
      productsRepo: getIt<ProductsRepo>(),
    ),
  );
}
