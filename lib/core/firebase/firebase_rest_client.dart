import 'package:http/http.dart' as http;
import 'package:shop_application/core/config/app_environment.dart';
import 'package:shop_application/core/network/api.dart';

abstract class FirebaseRestClient {
  Future<http.Response> get({
    required String path,
    String? authToken,
    Map<String, dynamic>? query,
  });

  Future<http.Response> post({
    required String path,
    required Map<String, dynamic> data,
    String? authToken,
  });

  Future<http.Response> put({
    required String path,
    required Object data,
    String? authToken,
    String? ifMatch,
  });

  Future<http.Response> patch({
    required String path,
    required Map<String, dynamic> data,
    String? authToken,
  });

  Future<http.Response> delete({required String path, String? authToken});
}

class FirebaseRestClientImpl implements FirebaseRestClient {
  final Api api;

  FirebaseRestClientImpl({required this.api});

  @override
  Future<http.Response> get({
    required String path,
    String? authToken,
    Map<String, dynamic>? query,
  }) {
    return api.get(
      url: _url(path),
      query: _query(authToken: authToken, query: query),
    );
  }

  @override
  Future<http.Response> post({
    required String path,
    required Map<String, dynamic> data,
    String? authToken,
  }) {
    return api.post(
      url: _url(path),
      query: _query(authToken: authToken),
      data: data,
    );
  }

  @override
  Future<http.Response> put({
    required String path,
    required Object data,
    String? authToken,
    String? ifMatch,
  }) {
    return api.put(
      url: _url(path),
      query: _query(authToken: authToken),
      data: data,
      headers: ifMatch == null ? null : {'if-match': ifMatch},
    );
  }

  @override
  Future<http.Response> patch({
    required String path,
    required Map<String, dynamic> data,
    String? authToken,
  }) {
    return api.patch(
      url: _url(path),
      query: _query(authToken: authToken),
      data: data,
    );
  }

  @override
  Future<http.Response> delete({required String path, String? authToken}) {
    return api.delete(
      url: _url(path),
      query: _query(authToken: authToken),
    );
  }

  String _url(String path) {
    final cleanPath = path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .join('/');

    return '${AppEnvironment.normalizedFirebaseDatabaseUrl}/$cleanPath.json';
  }

  Map<String, dynamic>? _query({
    String? authToken,
    Map<String, dynamic>? query,
  }) {
    final values = <String, dynamic>{
      if (query != null) ...query,
      if (authToken != null && authToken.isNotEmpty) 'auth': authToken,
    };

    return values.isEmpty ? null : values;
  }
}
