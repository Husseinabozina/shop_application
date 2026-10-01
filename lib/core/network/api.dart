import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class Api {
  Future<http.Response> get({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  });

  Future<http.Response> post({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  });

  Future<http.Response> put({
    required String url,
    Map<String, dynamic>? query,
    required Object data,
    String lang = 'ar',
    String? token,
    Map<String, String>? headers,
  });

  Future<http.Response> delete({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  });

  Future<http.Response> patch({
    required String url,
    Map<String, dynamic>? query,
    required Map<String, dynamic> data,
    String? token,
  });
}

class ApiImpl extends Api {
  final http.Client client = http.Client();

  @override
  Future<http.Response> get({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    _logRequest('GET', uri, null, response);
    return response;
  }

  @override
  Future<http.Response> post({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: data != null ? jsonEncode(data) : null,
    );
    _logRequest('POST', uri, data, response);
    return response;
  }

  @override
  Future<http.Response> put({
    required String url,
    Map<String, dynamic>? query,
    required Object data,
    String lang = 'ar',
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await client.put(
      uri,
      headers: {
        if (headers != null) ...headers,
        'Accept-Language': lang,
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    _logRequest('PUT', uri, data, response);
    return response;
  }

  @override
  Future<http.Response> delete({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: data != null ? jsonEncode(data) : null,
    );
    _logRequest('DELETE', uri, data, response);
    return response;
  }

  @override
  Future<http.Response> patch({
    required String url,
    Map<String, dynamic>? query,
    required Map<String, dynamic> data,
    String? token,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    _logRequest('PATCH', uri, data, response);
    return response;
  }

  void _logRequest(
    String method,
    Uri uri,
    Object? data,
    http.Response response,
  ) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('HTTP $method ${_redactUri(uri)} → ${response.statusCode}');
  }

  Uri _redactUri(Uri uri) {
    if (uri.queryParameters.isEmpty) {
      return uri;
    }

    final query = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      query[entry.key] = _isSensitiveKey(entry.key)
          ? '[REDACTED]'
          : entry.value;
    }

    return uri.replace(queryParameters: query);
  }

  bool _isSensitiveKey(String key) {
    switch (key.toLowerCase()) {
      case 'auth':
      case 'key':
      case 'token':
      case 'authorization':
        return true;
      default:
        return false;
    }
  }
}
