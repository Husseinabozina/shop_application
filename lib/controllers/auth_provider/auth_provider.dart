import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop_application/core/app_strings.dart';
import 'package:shop_application/core/helpers/cache_helpers.dart';
import 'package:shop_application/data/models/auth/user_response.dart';
import 'package:shop_application/data/repos/auth_repo.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepo authRepo;

  AuthProvider({required this.authRepo});

  UserResponse? userResponse;
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _timer;

  bool get isAuth => token != null;

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId => _userId;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _failureMessage;
  String? get failureMessage => _failureMessage;

  Future<void> login(String email, String password) async {
    _failureMessage = null;
    final result = await authRepo.login(email, password);

    result.when(
      success: (success) {
        _token = success.idToken;
        _userId = success.localId;
        _expiryDate = DateTime.now().add(
          Duration(
            seconds: int.tryParse(success.expiresIn) ?? 3600,
          ),
        );
        _successMessage = AppStrings.loginSuccessMessage;
        _autoLogout();
        notifyListeners();
      },
      failure: (failure) {
        _failureMessage = failure.message;
        notifyListeners();
      },
    );
  }

  Future<void> signup(String email, String password) async {
    _failureMessage = null;
    final result = await authRepo.signup(email, password);

    result.when(
      success: (success) {
        _token = success.idToken;
        _userId = success.localId;
        _expiryDate = DateTime.now().add(
          Duration(
            seconds: int.tryParse(success.expiresIn) ?? 3600,
          ),
        );
        _successMessage = AppStrings.signUpSuccessMessage;
        _autoLogout();
        notifyListeners();
      },
      failure: (failure) {
        _failureMessage = failure.message;
        notifyListeners();
      },
    );
  }

  Future<void> getUser() async {
    if (!CacheHelper.isLoggedIn()) {
      return;
    }

    final result = await authRepo.getUserData();
    result.when(
      success: (success) {
        userResponse = success;
        _token = success.token;
        _userId = success.userId;
        _expiryDate = DateTime.tryParse(success.expiryDate ?? '');
      },
      failure: (failure) {
        _failureMessage = failure.message;
      },
    );
  }

  Future<bool> tryAutoLogin() async {
    if (!CacheHelper.isLoggedIn()) {
      return false;
    }

    await getUser();

    if (_token == null ||
        _userId == null ||
        _expiryDate == null ||
        !_expiryDate!.isAfter(DateTime.now())) {
      await logOut();
      return false;
    }

    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> logOut() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
    await authRepo.logout();
  }

  void _autoLogout() {
    _timer?.cancel();

    if (_expiryDate == null) {
      return;
    }

    final timeToExpire = _expiryDate!.difference(DateTime.now());
    if (timeToExpire.isNegative) {
      return;
    }

    _timer = Timer(timeToExpire, logOut);
  }
}
