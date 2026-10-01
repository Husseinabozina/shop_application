import 'package:get_it/get_it.dart';
import 'package:shop_application/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/features/auth/domain/repositories/auth_repository.dart';
import 'package:shop_application/features/auth/domain/repositories/session_store.dart';
import 'package:shop_application/features/auth/data/datasources/local_session_store.dart';
import 'package:shop_application/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shop_application/features/cart/domain/repositories/cart_repository.dart';
import 'package:shop_application/features/cart/data/repositories/local_cart_repository.dart';
import 'package:shop_application/features/catalog/domain/repositories/product_repository.dart';
import 'package:shop_application/features/catalog/data/repositories/product_repository_impl.dart';
import 'package:shop_application/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shop_application/features/catalog/data/datasources/product_remote_data_source.dart';
import 'package:shop_application/features/address_book/data/datasources/address_book_remote_data_source.dart';
import 'package:shop_application/features/address_book/data/repositories/address_book_repository_impl.dart';
import 'package:shop_application/features/address_book/domain/repositories/address_book_repository.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/catalog/data/repositories/recently_viewed_repository_impl.dart';
import 'package:shop_application/features/catalog/data/repositories/sample_catalog_repository_impl.dart';
import 'package:shop_application/features/catalog/domain/repositories/sample_catalog_repository.dart';
import 'package:shop_application/features/catalog/domain/usecases/add_sample_catalog.dart';
import 'package:shop_application/features/catalog/presentation/controllers/sample_catalog_controller.dart';
import 'package:shop_application/features/catalog/domain/repositories/recently_viewed_repository.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:shop_application/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:shop_application/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:shop_application/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shop_application/features/orders/data/repositories/order_repository_impl.dart';
import 'package:shop_application/features/orders/domain/repositories/order_repository.dart';
import 'package:shop_application/features/payments/data/gateways/unconfigured_payment_gateway.dart';
import 'package:shop_application/features/payments/domain/gateways/payment_gateway.dart';

final GetIt getIt = GetIt.instance;

void setup() {
  if (getIt.isRegistered<Api>()) {
    return;
  }

  getIt.registerLazySingleton<Api>(() => ApiImpl());
  getIt.registerLazySingleton<FirebaseRestClient>(
    () => FirebaseRestClientImpl(api: getIt<Api>()),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(() => FirebaseAuthRemoteDataSource(getIt<Api>()));
  getIt.registerLazySingleton<SessionStore>(() => LocalSessionStore());
  getIt.registerLazySingleton<CartRepository>(() => LocalCartRepository());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: getIt<AuthRemoteDataSource>(), sessionStore: getIt<SessionStore>()),
  );
  getIt.registerLazySingleton<AuthController>(
    () => AuthController(repository: getIt<AuthRepository>()),
    dispose: (controller) => controller.dispose(),
  );

  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => FirebaseProductRemoteDataSource(database: getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductRemoteDataSource>()),
  );

  getIt.registerLazySingleton<RecentlyViewedRepository>(
    () => RecentlyViewedRepositoryImpl(),
  );
  getIt.registerLazySingleton<SampleCatalogRepository>(
    () => SampleCatalogRepositoryImpl(database: getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<AddSampleCatalog>(
    () => AddSampleCatalog(getIt<SampleCatalogRepository>()),
  );
  getIt.registerFactory<SampleCatalogController>(
    () => SampleCatalogController(addSampleCatalog: getIt<AddSampleCatalog>()),
  );
  getIt.registerFactory<RecentlyViewedController>(
    () =>
        RecentlyViewedController(repository: getIt<RecentlyViewedRepository>()),
  );

  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => FirebaseOrderRemoteDataSource(database: getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: getIt<OrderRemoteDataSource>()),
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
    () => AddressBookController(repository: getIt<AddressBookRepository>()),
  );

  getIt.registerLazySingleton<PaymentGateway>(
    () => const UnconfiguredPaymentGateway(),
  );

  getIt.registerLazySingleton<CheckoutRemoteDataSource>(
    () =>
        FirebaseCheckoutRemoteDataSource(database: getIt<FirebaseRestClient>()),
  );
  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(
      remoteDataSource: getIt<CheckoutRemoteDataSource>(),
      paymentGateway: getIt<PaymentGateway>(),
    ),
  );
  getIt.registerFactory<CheckoutController>(
    () => CheckoutController(repository: getIt<CheckoutRepository>()),
  );
}
