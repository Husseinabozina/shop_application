import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/repositories/order_repository.dart';
import 'package:shop_application/features/orders/presentation/controllers/order_controller.dart';
import 'package:shop_application/screens/orders_screen.dart';

class _OrderRepository implements OrderRepository {
  int calls = 0;
  bool failNextRequest = false;
  Future<List<Order>>? pending;
  String? requestedUserId;
  String? requestedToken;

  @override
  Future<List<Order>> fetchOrders({
    required String userId,
    required String accessToken,
  }) async {
    calls++;
    requestedUserId = userId;
    requestedToken = accessToken;
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('Could not load test orders');
    }
    if (pending != null) {
      return pending!;
    }
    return <Order>[];
  }

  @override
  Future<Order> fetchOrder({
    required String userId,
    required String orderId,
    required String accessToken,
  }) => throw UnsupportedError('Order details are not used in this test');
}

Widget _app(OrderController controller, GlobalKey<NavigatorState> navigator) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OrderController>.value(value: controller),
      ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.light(),
      home: Consumer<OrderController>(
        builder: (_, orders, __) => Scaffold(
          body: Text(orders.isLoading ? 'Loading history' : 'Store home'),
        ),
      ),
      routes: {OrdersScreen.routeName: (_) => const OrdersScreen()},
    ),
  );
}

void main() {
  late _OrderRepository repository;
  late OrderController controller;
  late GlobalKey<NavigatorState> navigator;

  setUp(() {
    repository = _OrderRepository();
    controller = OrderController(
      repository: repository,
      userId: 'test-owner',
      token: 'test-token',
    );
    navigator = GlobalKey<NavigatorState>();
  });

  tearDown(() => controller.dispose());

  testWidgets('opening and reopening orders is safe with existing listeners', (
    tester,
  ) async {
    await tester.pumpWidget(_app(controller, navigator));
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed(OrdersScreen.routeName);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(repository.calls, 1);
    expect(repository.requestedUserId, 'test-owner');
    expect(repository.requestedToken, 'test-token');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed(OrdersScreen.routeName);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(repository.calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('orders remains loading until the request completes', (
    tester,
  ) async {
    final response = Completer<List<Order>>();
    repository.pending = response.future;
    await tester.pumpWidget(_app(controller, navigator));
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed(OrdersScreen.routeName);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(controller.isLoading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.calls, 1);
    response.complete([]);
    await tester.pumpAndSettle();
    expect(controller.isLoading, isFalse);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed orders can be retried without build-time notifications', (
    tester,
  ) async {
    repository.failNextRequest = true;
    await tester.pumpWidget(_app(controller, navigator));
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed(OrdersScreen.routeName);
    await tester.pumpAndSettle();
    expect(find.text('Could not load test orders'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
