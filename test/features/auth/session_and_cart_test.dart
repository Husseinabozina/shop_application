import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shop_application/features/auth/data/datasources/local_session_store.dart';
import 'package:shop_application/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shop_application/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shop_application/features/cart/data/repositories/local_cart_repository.dart';
import 'package:shop_application/features/cart/presentation/controllers/cart_controller.dart';

import '../../support/auth_test_api.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
  });

  test('existing sessions restore, logout clears storage, and expired sessions are rejected', () async {
    final api = AuthTestApi(http.Response('{}', 400));
    final repository = AuthRepositoryImpl(remote: FirebaseAuthRemoteDataSource(api),
      sessionStore: LocalSessionStore());
    final auth = AuthController(repository: repository);
    addTearDown(auth.dispose);
    await CacheHelper.saveUserData('token', 'owner', DateTime.now().add(const Duration(hours: 1)));
    expect(await auth.tryAutoLogin(), isTrue);
    expect(auth.token, 'token');
    expect(auth.userId, 'owner');
    expect(api.calls, 0);
    await auth.logOut();
    expect(auth.isAuth, isFalse);
    expect(CacheHelper.isLoggedIn(), isFalse);
    await CacheHelper.saveUserData('expired', 'owner', DateTime.now().subtract(const Duration(seconds: 1)));
    expect(await auth.tryAutoLogin(), isFalse);
    expect(CacheHelper.isLoggedIn(), isFalse);
    expect(api.calls, 0);
  });

  test('cart writes survive restart, stay account-scoped, and checkout clear persists', () async {
    final repository = LocalCartRepository();
    final first = CartController(repository: repository, userId: 'owner');
    addTearDown(first.dispose);
    first.addItem('lamp', 25, 'Lamp', maxQuantity: 2);
    first.addItem('lamp', 25, 'Lamp', maxQuantity: 2);
    first.removeSingleItem('lamp');
    first.addItem('mug', 10, 'Mug');
    await first.flush();
    final restored = CartController(repository: LocalCartRepository(), userId: 'owner');
    addTearDown(restored.dispose);
    expect(restored.items['lamp']?.quantity, 1);
    expect(restored.totalPrice, 35);
    final other = CartController(repository: repository, userId: 'other');
    addTearDown(other.dispose);
    expect(other.items, isEmpty);
    other.addItem('bag', 50, 'Bag');
    await other.flush();
    expect(repository.load('owner').keys, ['lamp', 'mug']);
    restored.clear();
    await restored.flush();
    expect(LocalCartRepository().load('owner'), isEmpty);
    expect(LocalCartRepository().load('other').keys, ['bag']);
  });

  test('damaged local entries do not hide valid cart items', () async {
    await CacheHelper.setStringList('cart_items_v1_owner', [
      'not JSON',
      jsonEncode({'productId': 'invalid', 'quantity': -1, 'price': 10, 'title': 'Bad'}),
      jsonEncode({'productId': 'lamp', 'quantity': 2, 'price': 25, 'title': 'Lamp'}),
    ]);
    final cart = CartController(repository: LocalCartRepository(), userId: 'owner');
    addTearDown(cart.dispose);
    expect(cart.items.keys, ['lamp']);
    expect(cart.totalPrice, 50);
  });
}
