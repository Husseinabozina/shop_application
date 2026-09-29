import 'package:get_it/get_it.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/data/repos/auth_repo.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/data/services/auth_services.dart';
import 'package:shop_application/data/services/order_services.dart';
import 'package:shop_application/data/services/product_service.dart';

final GetIt getIt = GetIt.instance;

void setup() {
  if (getIt.isRegistered<Api>()) {
    return;
  }

  getIt.registerLazySingleton<Api>(() => ApiImpl());

  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(getIt<Api>()),
  );
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(authService: getIt<AuthService>()),
  );
  getIt.registerLazySingleton<AuthProvider>(
    () => AuthProvider(authRepo: getIt<AuthRepo>()),
  );

  getIt.registerLazySingleton<ProductService>(
    () => ProductServiceImpl(api: getIt<Api>()),
  );
  getIt.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(getIt<ProductService>()),
  );

  getIt.registerLazySingleton<OrderServices>(
    () => OrderServicesImpl(getIt<Api>()),
  );
  getIt.registerLazySingleton<OrderRepo>(
    () => OrderRepoImpl(orderServices: getIt<OrderServices>()),
  );
}
