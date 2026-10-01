import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shop_application/core/config/app_environment.dart';
import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/core/network/error_handler.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    String urlSegment,
  );


}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final Api api;

  FirebaseAuthRemoteDataSource(this.api);

  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    String urlSegment,
  ) async {
    try {
      final response = await api.post(
        url: 'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment',
        query: {'key': AppEnvironment.firebaseWebApiKey},
        data: {'email': email, 'password': password, 'returnSecureToken': true},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final failure = ExceptionHandler.handleFirebaseAuthResponse(response);
        if (kDebugMode) {
          debugPrint(
            'Firebase Auth $urlSegment failed: ${failure.errorCode} '
            '(HTTP ${response.statusCode})',
          );
        }
        throw failure;
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      return responseData;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

}
