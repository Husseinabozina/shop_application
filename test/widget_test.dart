import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/core/theme/app_theme.dart';

void main() {
  testWidgets('storefront theme renders a basic app shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: Text('MyShop'),
          ),
        ),
      ),
    );

    expect(find.text('MyShop'), findsOneWidget);
  });
}
