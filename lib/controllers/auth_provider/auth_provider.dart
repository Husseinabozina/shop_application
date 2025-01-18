import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/data/models/auth/user_response.dart';
import 'package:shop_application/data/repos/auth_repo.dart';

class AuthProvider with ChangeNotifier {
  AuthRepo authRepo;

  AuthProvider({required this.authRepo});
  UserResponse? userResponse;
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? timer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token!;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  String? _successMessage;
  String? get successMessage {
    return _successMessage;
  }

  String? _failureMessage; //
  String? get failureMessage {
    return _failureMessage; // Getter for failure message
  }

  Future<void> login(String email, String password) async {
    final result = await authRepo.login(email, password);
    result.when(success: (success) {
      _successMessage = AppStrings.loginSuccessMessage;
      notifyListeners();
    }, failure: (failure) {
      _failureMessage = failure.message;
    });
  }

  Future<void> signup(String email, String password) async {
    final result = await authRepo.signup(email, password);
    result.when(success: (success) {
      _successMessage = AppStrings.signUpSuccessMessage;
      notifyListeners();
    }, failure: (failure) {
      _failureMessage = failure.message;
    });
  }

  Future<void> getUser() async {
    if (CacheHelper.isLoggedIn()) {
      final result = await authRepo.getUserData();
      result.when(success: (success) {
        userResponse = success;
        notifyListeners();
      }, failure: (failure) {
        _failureMessage = failure.message;
      });
    }
  }

  Future<bool> tryAutoLogin() async {
    if (CacheHelper.isLoggedIn()) {
      return false;
    }

    await getUser();

    final expiryDate = DateTime.parse(userResponse!.expiryDate as String);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _expiryDate = expiryDate;
    _token = userResponse!.token;
    _userId = userResponse!.userId;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logOut() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }

    notifyListeners();
    await authRepo.logout();
  }

  void _autoLogout() {
    if (timer != null) {
      timer!.cancel();
    }
    final timeToExpire = _expiryDate!.difference(DateTime.now()).inSeconds;
    timer = Timer(Duration(seconds: timeToExpire), logOut);
  }
}
