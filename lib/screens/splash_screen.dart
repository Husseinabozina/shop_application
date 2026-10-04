import 'package:flutter/material.dart';
import 'package:shop_application/widgets/brand_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandMark(size: 96),
            SizedBox(height: 18),
            Text(
              'MyShop',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 22),
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Getting your shop ready…',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
