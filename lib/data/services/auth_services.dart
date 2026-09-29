import 'dart:convert';

import 'package:shop_application/core/constant.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/core/network/error_handler.dart';

abstract class AuthService {
  Future<dynamic> authenticate(
    String email,
    String password,
    String urlSegment,
  );

  Future<Map<String, dynamic>> getUserData();
  Future<void> logout();
}

class AuthServiceImpl implements AuthService {
  final Api api;

  AuthServiceImpl(this.api);

  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    String urlSegment,
  ) async {
    try {
      final response = await api.post(
        url:
            'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$apiKey',
        data: {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (responseData['error'] != null) {
        throw ExceptionHandler.handle(responseData['error']);
      }

      final expiresInSeconds =
          int.tryParse(responseData['expiresIn']?.toString() ?? '') ?? 3600;
      final expiryDate =
          DateTime.now().add(Duration(seconds: expiresInSeconds));

      await CacheHelper.saveUserData(
        responseData['idToken'] as String,
        responseData['localId'] as String,
        expiryDate,
      );

      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await CacheHelper.clearUserData();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserData() async {
    try {
      return await CacheHelper.getUserData();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
