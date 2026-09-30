import 'package:http/http.dart' as http;
import 'package:shop_application/core/network/api.dart';

class AuthTestApi implements Api {
  AuthTestApi(this.response);

  http.Response response;
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastData;
  int calls = 0;

  @override
  Future<http.Response> post({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    calls++;
    lastUrl = url;
    lastQuery = query;
    lastData = data;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected API call: ${invocation.memberName}');
}
