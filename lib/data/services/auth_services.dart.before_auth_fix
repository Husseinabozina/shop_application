import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop_application/core/constant.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/core/network/error_handler.dart';

abstract class AuthService {
  Future<dynamic> authenticate(
      String email, String password, String urlSegment);
  Future<Map<String, dynamic>> getUserData();
  Future<void> logout();
}

class AuthServiceImpl implements AuthService {
  final Api api;
  AuthServiceImpl(this.api);

  @override
  Future authenticate(String email, String password, String urlSegment) async {
    try {
      final response = await api.post(
          url:
              "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$apiKey",
          data: {'email': email, 'password': password});

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        throw ExceptionHandler.handle(responseData['error']);
      }

      // On successful authentication, save user data using CacheHelper
      await CacheHelper.saveUserData(responseData['idToken'],
          responseData['localId'], DateTime.parse(responseData['expiresIn']));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> logout() async {
    // Clear user data when logging out
    try {
      await CacheHelper.clearUserData();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserData() {
    try {
      return CacheHelper.getUserData();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
