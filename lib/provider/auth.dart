import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/models/http_exception.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? timer;
  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_token != null &&
        _expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now())) {
      return _token!;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyBWyn5fCqngGVU03wvRoBVFpyAd_CxfAL0');
    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(message: '${responseData['error']['message']}');
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();

      final userData = json.encode({
        'token': token,
        'expiryDate': _expiryDate!.toIso8601String(),
        'userId': userId
      });
      print('RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRr');
      prefs.setString('UserData', userData);
    } catch (error) {
      print('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
      throw error;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, "signUp");
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, "signInWithPassword");
  }

  Future<bool> tryAutoLogin() async {
    print('wwwwwwwwwwwwwwwwwwwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW');
    final prefs = await SharedPreferences.getInstance();
    print('ssssssssssssssssssssssssssssssssssssssssssssssssssss');
    if (!prefs.containsKey('UserData')) {
      print('kjkjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj');
      return false;
    }
    final extractedData =
        json.decode(prefs.getString('UserData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedData['expiryDate'] as String);
    if (expiryDate.isBefore(DateTime.now())) {
      print('ya the  expiryDate= ${expiryDate.isBefore(DateTime.now())} ');
      print('nNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN');
      return false;
    }
    _token = extractedData['token'] as String;
    _expiryDate = expiryDate;
    _userId = extractedData['userId'] as String;

    notifyListeners();
    _autoLogout();
    print(
        'expirty Date is After DateTime.now() yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy');
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
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if (timer != null) {
      timer!.cancel();
    }
    final timeToExpire = _expiryDate!.difference(DateTime.now()).inSeconds;
    timer = Timer(Duration(seconds: timeToExpire), logOut);
  }
}
