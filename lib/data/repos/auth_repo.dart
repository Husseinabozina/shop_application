import 'package:http/http.dart';
import 'package:shop_application/core/network/api_result.dart';
import 'package:shop_application/core/network/error_handler.dart';
import 'package:shop_application/data/models/auth/login_response.dart';
import 'package:shop_application/data/models/auth/register_response.dart';
import 'package:shop_application/data/models/auth/user_response.dart';
import 'package:shop_application/data/services/auth_services.dart';

abstract class AuthRepo {
  Future<APIResult<RegisterResponse>> signup(String email, String password);

  Future<APIResult<LoginResponse>> login(String email, String password);
  Future<APIResult<UserResponse>> getUserData();

  Future<APIResult<void>> logout();
}

class AuthRepoImpl implements AuthRepo {
  AuthService authService;

  AuthRepoImpl({required this.authService});

  @override
  Future<APIResult<LoginResponse>> login(String email, String password) async {
    try {
      final data =
          await authService.authenticate(email, password, "signInWithPassword");
      final result = LoginResponse.fromJson(data);
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<RegisterResponse>> signup(
      String email, String password) async {
    try {
      final data = await authService.authenticate(email, password, "signUp");
      final result = RegisterResponse.fromJson(data);
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<UserResponse>> getUserData() async {
    try {
      final data = await authService.getUserData();
      final result = UserResponse.fromJson(data);
      return APIResult.success(result);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }

  @override
  Future<APIResult<void>> logout() async {
    try {
      await authService.logout();
      return APIResult.success(null);
    } catch (e) {
      return APIResult.failure(ExceptionHandler.handle(e));
    }
  }
}
