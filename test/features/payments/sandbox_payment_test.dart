import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/core/theme/app_theme.dart';
import 'package:shop_application/features/payments/presentation/controllers/sandbox_payment_controller.dart';
import 'package:shop_application/features/payments/presentation/widgets/sandbox_payment_host.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/features/payments/data/datasources/sandbox_payment_store.dart';
import 'package:shop_application/features/payments/data/gateways/myfatoorah_sandbox_gateway.dart';
import 'package:shop_application/features/payments/data/repositories/sandbox_checkout_repository_impl.dart';
import 'package:shop_application/features/payments/domain/entities/sandbox_payment.dart';

import '../../support/portfolio_capture.dart';

import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';
import 'package:shop_application/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/address_book/presentation/widgets/address_form_sheet.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:shop_application/features/checkout/presentation/screens/checkout_screen.dart';

const _order = <String, dynamic>{
  'amount': 180,
  'currency': 'EGP',
  'datetime': '2026-10-04T05:00:00Z',
  'status': 'placed',
  'shippingAddress': {'fullName': 'Private name', 'phone': 'Private phone'},
  'products': [
    {'id': 'p1', 'title': 'Product', 'quantity': 1, 'price': 155},
  ],
};

class _Database implements FirebaseRestClient {
  final records = <String, Map<String, dynamic>>{};
  int writes = 0;
  bool failSave = false;
  @override
  Future<http.Response> get({
    required String path,
    String? authToken,
    Map<String, dynamic>? query,
  }) async =>
      http.Response(
        jsonEncode(records[path]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
  @override
  Future<http.Response> put({
    required String path,
    required Object data,
    String? authToken,
    String? ifMatch,
  }) async {
    expect(ifMatch, 'null_etag');
    if (failSave) return http.Response('{}', 503);
    if (records.containsKey(path)) return http.Response('{}', 412);
    writes++;
    records[path] = Map<String, dynamic>.from(data as Map);
    return http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected database action');
}

void main() {
  setUpAll(preparePortfolioCapture);
  late String reference;
  late int creates;
  late String status;
  late bool offline;
  late bool mismatched;
  late String checkoutUrl;
  late _Database database;
  late MyFatoorahSandboxGateway gateway;
  late SandboxPaymentStore store;
  SandboxCheckoutRepositoryImpl repository() => SandboxCheckoutRepositoryImpl(
        gateway: gateway,
        store: store,
        database: database,
      );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reference = '';
    creates = 0;
    status = 'Pending';
    offline = false;
    mismatched = false;
    checkoutUrl =
        'https://demo.myfatoorah.com/En/PayInvoice/Checkout?invoiceKey=test';
    database = _Database();
    store = SandboxPaymentStore();
    gateway = MyFatoorahSandboxGateway(
      client: MockClient((request) async {
        expect(request.url.host, 'apitest.myfatoorah.com');
        expect(request.followRedirects, isFalse);
        expect(
          request.headers['Content-Type']?.split(';').first,
          'application/json',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        Map<String, dynamic> data;
        switch (request.url.path) {
          case '/v2/InitiatePayment':
            expect(body, {'InvoiceAmount': 1, 'CurrencyIso': 'KWD'});
            data = {
              'PaymentMethods': [
                {
                  'PaymentMethodId': 44,
                  'PaymentMethodEn': 'VISA/MASTER',
                  'IsDirectPayment': true,
                },
                {
                  'PaymentMethodId': 71,
                  'PaymentMethodEn': 'VISA/MASTER',
                  'IsDirectPayment': false,
                },
              ],
            };
            break;
          case '/v2/ExecutePayment':
            creates++;
            expect(body['PaymentMethodId'], 71);
            expect(body['InvoiceValue'], 1);
            expect(body['DisplayCurrencyIso'], 'KWD');
            expect(body['CustomerName'], 'MyShop Demo');
            expect(
              body.keys,
              unorderedEquals([
                'PaymentMethodId',
                'InvoiceValue',
                'DisplayCurrencyIso',
                'CustomerName',
                'Language',
                'CustomerReference',
              ]),
            );
            reference = body['CustomerReference'] as String;
            data = {
              'InvoiceId': 123,
              'CustomerReference': reference,
              'PaymentURL': checkoutUrl,
            };
            break;
          case '/v2/GetPaymentStatus':
            expect(body, {'Key': '123', 'KeyType': 'InvoiceId'});
            if (offline) throw http.ClientException('Offline');
            data = {
              'InvoiceId': 123,
              'CustomerReference': mismatched ? 'wrong' : reference,
              'InvoiceValue': 1,
              'InvoiceDisplayValue': '1.000 KD',
              'InvoiceStatus': status,
            };
            break;
          default:
            throw StateError('Unexpected provider operation');
        }
        return http.Response(
          jsonEncode({'IsSuccess': true, 'Data': data}),
          200,
        );
      }),
    );
  });
  tearDown(() => gateway.close());

  testWidgets(
    'checkout card button opens hosted payment, address editing stays separate, and Paid exits checkout',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'UserData': jsonEncode({
          'userId': 'owner',
          'token': 'token',
          'expiryDate':
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        }),
      });
      await CacheHelper.init();
      await getIt.reset();
      setup();
      addTearDown(() => getIt.reset());
      final auth = getIt<AuthController>();
      expect(await auth.tryAutoLogin(), isTrue);
      final checkout = getIt<CheckoutController>();
      final addressBook = getIt<AddressBookController>();
      addTearDown(checkout.dispose);
      addTearDown(addressBook.dispose);
      await checkout.initialize(
        items: const [
          CheckoutLineItem(
            productId: 'p1',
            title: 'Product',
            quantity: 1,
            unitPrice: 155,
          ),
        ],
      );
      await checkout.setAddress(
        const CheckoutAddress(
          fullName: 'Private name',
          phone: 'Private phone',
          addressLine1: 'Test street',
          city: 'Cairo',
          country: 'Egypt',
        ),
      );
      checkout.selectPaymentMethod(
        checkout.paymentMethods.singleWhere(
          (method) => method.type == PaymentMethodType.card,
        ),
      );
      final opened = <Uri>[];
      var completed = 0;
      final payment = SandboxPaymentController(
        repository: repository(),
        userId: 'owner',
        accessToken: 'token',
        onCompleted: (_) => completed++,
        openUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      addTearDown(payment.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: checkout),
            ChangeNotifierProvider.value(value: addressBook),
            ChangeNotifierProvider.value(value: payment),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            builder: (_, child) => SandboxPaymentHost(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CheckoutScreen(),
                    ),
                  ),
                  child: const Text('Open checkout'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open checkout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.byType(AddressFormSheet), findsOneWidget);
      expect(creates, 0);
      Navigator.of(tester.element(find.byType(AddressFormSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to test payment • 1 KWD'));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(creates, 1);
      expect(database.writes, 0);
      expect(completed, 0);
      expect(payment.attempt?.orderTotal, 180);
      status = 'Paid';
      await payment.check();
      await tester.pumpAndSettle();
      expect(payment.completedOrderId, 'sandbox_myfatoorah_123',
          reason: payment.message);
      expect(database.writes, 1);
      expect(completed, 1);
      expect(database.records.values.single['shippingAddress']['fullName'],
          'Private name');
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(creates, 1);
      expect(tester.takeException(), isNull);
      await auth.logOut();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'compact large-text recovery banner reopens the same link and saves only after manual Paid verification',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = 0;
      final opened = <Uri>[];
      final controller = SandboxPaymentController(
        repository: repository(),
        userId: 'owner',
        accessToken: 'token',
        onCompleted: (_) {
          completed++;
        },
        openUrl: (url) async {
          opened.add(url);
          return true;
        },
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: RepaintBoundary(
            key: const ValueKey('portfolio-capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: SandboxPaymentHost(child: child!),
              ),
              home: const Scaffold(
                body: Center(child: Text('Your cart is kept')),
              ),
            ),
          ),
        ),
      );
      await controller.start(_order);
      await controller.check();
      await tester.pumpAndSettle();
      expect(controller.attempt, isNotNull);
      expect(completed, 0);
      expect(database.writes, 0);
      expect(tester.takeException(), isNull);
      await capturePortfolio(tester, '06-sandbox-pending');
      await tester.ensureVisible(find.text('Open test payment'));
      await tester.tap(find.text('Open test payment'));
      await tester.pumpAndSettle();
      expect(opened.length, 2);
      expect(opened.first, opened.last);
      expect(creates, 1);
      status = 'Paid';
      await tester.ensureVisible(find.text('Check payment result'));
      await tester.tap(find.text('Check payment result'));
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(database.writes, 1);
      expect(controller.attempt, isNull);
      expect(tester.takeException(), isNull);
      await capturePortfolio(tester, '07-sandbox-confirmed');
    },
  );

  test(
      'one hosted attempt survives restart, account isolation, pending and offline; no order is created',
      () async {
    final repo = repository();
    final attempts = await Future.wait([
      repo.begin(userId: 'owner', order: _order),
      repo.begin(userId: 'owner', order: _order),
    ]);
    expect(attempts.first.invoiceId, attempts.last.invoiceId);
    expect(creates, 1);
    final restored = await repository().restore('owner');
    expect(restored!.reference, reference);
    expect(await store.read('other'), isNull);
    expect(
      await repo.checkAndSave(
        attempt: restored,
        accessToken: 'token',
        isCurrentAccount: () => true,
      ),
      SandboxPaymentStatus.pending,
    );
    offline = true;
    await expectLater(
      repo.checkAndSave(
        attempt: restored,
        accessToken: 'token',
        isCurrentAccount: () => true,
      ),
      throwsA(isA<http.ClientException>()),
    );
    expect(await store.read('owner'), isNotNull);
    expect(database.writes, 0);
    expect(creates, 1);
  });

  test(
      'paid save retries and repeated verification create one EGP demo order with a separate KWD receipt',
      () async {
    final repo = repository();
    final attempt = await repo.begin(userId: 'owner', order: _order);
    status = 'Paid';
    database.failSave = true;
    await expectLater(
      repo.checkAndSave(
        attempt: attempt,
        accessToken: 'token',
        isCurrentAccount: () => true,
      ),
      throwsException,
    );
    expect(await store.read('owner'), isNotNull);
    database.failSave = false;
    for (var i = 0; i < 2; i++) {
      expect(
        await repo.checkAndSave(
          attempt: attempt,
          accessToken: 'token',
          isCurrentAccount: () => true,
        ),
        SandboxPaymentStatus.paid,
      );
    }
    expect(database.writes, 1);
    expect(creates, 1);
    expect(await store.read('owner'), isNull);
    final saved = database.records.values.single;
    expect(saved['amount'], 180);
    expect(saved['currency'], 'EGP');
    expect(saved['paymentStatus'], 'sandbox_paid');
    expect(saved['sandboxPayment']['amount'], 1);
    expect(saved['sandboxPayment']['currency'], 'KWD');
  });

  test(
    'mismatched paid receipt and account switch never save an order',
    () async {
      final repo = repository();
      final attempt = await repo.begin(userId: 'owner', order: _order);
      status = 'Paid';
      mismatched = true;
      await expectLater(
        repo.checkAndSave(
          attempt: attempt,
          accessToken: 'token',
          isCurrentAccount: () => true,
        ),
        throwsException,
      );
      mismatched = false;
      await expectLater(
        repo.checkAndSave(
          attempt: attempt,
          accessToken: 'token',
          isCurrentAccount: () => false,
        ),
        throwsException,
      );
      expect(database.writes, 0);
      expect(await store.read('owner'), isNotNull);
    },
  );

  test(
      'invalid/live hosted URLs are rejected; cancelled invoice preserves order data and allows a new attempt',
      () async {
    checkoutUrl = 'https://portal.myfatoorah.com/PayInvoice';
    await expectLater(
      repository().begin(userId: 'owner', order: _order),
      throwsException,
    );
    for (final url in [
      'http://demo.myfatoorah.com/pay',
      'https://demo.myfatoorah.com.evil.test/pay',
      'https://user@demo.myfatoorah.com/pay',
      'https://demo.myfatoorah.com:444/pay',
    ]) {
      expect(SandboxPaymentAttempt.isSandboxUrl(Uri.parse(url)), isFalse);
    }
    checkoutUrl = 'https://demo.myfatoorah.com/pay';
    final repo = repository();
    final attempt = await repo.begin(userId: 'owner', order: _order);
    status = 'Canceled';
    expect(
      await repo.checkAndSave(
        attempt: attempt,
        accessToken: 'token',
        isCurrentAccount: () => true,
      ),
      SandboxPaymentStatus.cancelled,
    );
    expect(database.writes, 0);
    expect(await store.read('owner'), isNull);
  });
}
