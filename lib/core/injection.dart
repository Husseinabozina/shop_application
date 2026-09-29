import 'package:get_it/get_it.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/data/repos/auth_repo.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/data/repos/products_repo.dart';
import 'package:shop_application/data/services/auth_services.dart';
import 'package:shop_application/data/services/order_services.dart';
import 'package:shop_application/data/services/product_service.dart';
import 'package:shop_application/features/address_book/data/datasources/address_book_remote_data_source.dart';
import 'package:shop_application/features/address_book/data/repositories/address_book_repository_impl.dart';
import 'package:shop_application/features/address_book/domain/repositories/address_book_repository.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:shop_application/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:shop_application/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';

final GetIt getIt = GetIt.instance;

void setup() {
  if (getIt.isRegistered<Api>()) {
    return;
  }

  getIt.registerLazySingleton<Api>(() => ApiImpl());
  getIt.registerLazySingleton<FirebaseRestClient>(
    () => FirebaseRestClientImpl(api: getIt<Api>()),
  );

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
    () => ProductServiceImpl(database: getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(getIt<ProductService>()),
  );

  getIt.registerLazySingleton<OrderServices>(
    () => OrderServicesImpl(getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<OrderRepo>(
    () => OrderRepoImpl(orderServices: getIt<OrderServices>()),
  );

  getIt.registerLazySingleton<AddressBookRemoteDataSource>(
    () => FirebaseAddressBookRemoteDataSource(
      database: getIt<FirebaseRestClient>(),
    ),
  );
  getIt.registerLazySingleton<AddressBookRepository>(
    () => AddressBookRepositoryImpl(
      remoteDataSource: getIt<AddressBookRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<AddressBookController>(
    () => AddressBookController(
      repository: getIt<AddressBookRepository>(),
    ),
  );

  getIt.registerLazySingleton<CheckoutRemoteDataSource>(
    () => FirebaseCheckoutRemoteDataSource(
      database: getIt<FirebaseRestClient>(),
    ),
  );
  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(
      remoteDataSource: getIt<CheckoutRemoteDataSource>(),
    ),
  );
  getIt.registerFactory<CheckoutController>(
    () => CheckoutController(
      repository: getIt<CheckoutRepository>(),
    ),
  );
}
