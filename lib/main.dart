import 'package:flutter/material.dart';
import 'package:shop_application/app/app.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  setup();

  runApp(const MyShopApp());
}
