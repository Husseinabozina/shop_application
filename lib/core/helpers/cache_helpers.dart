import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_application/core/network/error_handler.dart';

class CacheHelper {
  static late SharedPreferences _prefs;

  // Define keys as constants
  static const String _userDataKey = 'UserData';
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _expiryDateKey = 'expiryDate';

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save user data to SharedPreferences
  static Future<void> saveUserData(
      String token, String userId, DateTime expiryDate) async {
    final userData = json.encode({
      _tokenKey: token,
      _userIdKey: userId,
      _expiryDateKey: expiryDate.toIso8601String(),
    });
    await _prefs.setString(_userDataKey, userData);
  }

  // Get user data from SharedPreferences
  static Future<Map<String, dynamic>> getUserData() async {
    if (!_prefs.containsKey(_userDataKey)) {
      throw ExceptionHandler.handle('No user data found');
    }
    final extractedData =
        json.decode(_prefs.getString(_userDataKey)!) as Map<String, dynamic>;
    return extractedData;
  }

  // Clear user data from SharedPreferences
  static Future<void> clearUserData() async {
    await _prefs.remove(_userDataKey);
  }

  // Check if user is logged in by verifying if 'UserData' exists
  static bool isLoggedIn() {
    return _prefs.containsKey(_userDataKey);
  }
}
