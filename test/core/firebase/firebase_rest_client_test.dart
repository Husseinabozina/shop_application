import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shop_application/core/config/app_environment.dart';
import 'package:shop_application/core/firebase/firebase_rest_client.dart';
import 'package:shop_application/core/network/api.dart';

class _RecordingApi implements Api {
  String? lastMethod;
  String? lastUrl;
  Map<String, dynamic>? lastQuery;
  Object? lastData;

  http.Response _record({
    required String method,
    required String url,
    Map<String, dynamic>? query,
    Object? data,
  }) {
    lastMethod = method;
    lastUrl = url;
    lastQuery = query;
    lastData = data;
    return http.Response('{}', 200);
  }

  @override
  Future<http.Response> get({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return _record(
      method: 'GET',
      url: url,
      query: query,
      data: data,
    );
  }

  @override
  Future<http.Response> post({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return _record(
      method: 'POST',
      url: url,
      query: query,
      data: data,
    );
  }

  @override
  Future<http.Response> put({
    required String url,
    Map<String, dynamic>? query,
    required Object data,
    String lang = 'ar',
    String? token,
  }) async {
    return _record(
      method: 'PUT',
      url: url,
      query: query,
      data: data,
    );
  }

  @override
  Future<http.Response> delete({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return _record(
      method: 'DELETE',
      url: url,
      query: query,
      data: data,
    );
  }

  @override
  Future<http.Response> patch({
    required String url,
    Map<String, dynamic>? query,
    required Map<String, dynamic> data,
    String? token,
  }) async {
    return _record(
      method: 'PATCH',
      url: url,
      query: query,
      data: data,
    );
  }
}

void main() {
  late _RecordingApi api;
  late FirebaseRestClient client;

  setUp(() {
    api = _RecordingApi();
    client = FirebaseRestClientImpl(api: api);
  });

  test('builds Firebase paths and keeps auth in query parameters', () async {
    await client.get(
      path: '/order/user-1/',
      authToken: 'test-token',
      query: const {
        'orderBy': '"datetime"',
      },
    );

    expect(api.lastMethod, 'GET');
    expect(
      api.lastUrl,
      AppEnvironment.normalizedFirebaseDatabaseUrl +
          '/order/user-1.json',
    );
    expect(api.lastQuery?['auth'], 'test-token');
    expect(api.lastQuery?['orderBy'], '"datetime"');
  });

  test('routes writes through the configured Firebase database', () async {
    await client.post(
      path: 'addresses/user-1',
      authToken: 'test-token',
      data: const {
        'label': 'Home',
      },
    );

    expect(api.lastMethod, 'POST');
    expect(
      api.lastUrl,
      AppEnvironment.normalizedFirebaseDatabaseUrl +
          '/addresses/user-1.json',
    );
    expect(api.lastData, const {'label': 'Home'});
  });
}
