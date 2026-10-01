import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_application/core/network/api.dart';

/// HTTP boundary fake: real app controllers, repositories, and serializers run.
class MemoryShopApi implements Api {
  final products = <String, dynamic>{};
  final favorites = <String, dynamic>{};
  final orders = <String, dynamic>{};
  int sampleWrites = 0;
  int orderWrites = 0;
  int productWrites = 0;
  int favoriteWrites = 0;
  bool failFavoriteWrites = false;
  int? failSampleAt;
  String? orderUser;
  Map<String, dynamic>? placedOrder;
  final address = <String, dynamic>{
    'label': 'Home',
    'fullName': 'Demo Shopper',
    'phone': '01000000000',
    'addressLine1': '10 Test Street',
    'city': 'Cairo',
    'country': 'Egypt',
    'isDefault': true,
  };

  String _path(String url) => Uri.parse(
    url,
  ).path.replaceFirst(RegExp(r'^/'), '').replaceFirst(RegExp(r'\.json$'), '');
  http.Response _response(Object? data, [int status = 200]) =>
      http.Response(jsonEncode(data), status);

  @override
  Future<http.Response> get({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final path = _path(url);
    if (path == 'products') {
      if (query?['shallow'] == 'true')
        return _response({for (final id in products.keys) id: true});
      if (query?['equalTo'] != null) {
        final owner = jsonDecode(query!['equalTo'] as String);
        return _response(
          Map.fromEntries(
            products.entries.where(
              (entry) => entry.value['creatorId'] == owner,
            ),
          ),
        );
      }
      return _response(products);
    }
    if (path.startsWith('products/'))
      return _response(products[path.split('/').last]);
    if (path.startsWith('userfavorite/')) return _response(favorites);
    if (path.startsWith('addresses/')) return _response({'home': address});
    if (path.startsWith('order/')) return _response(orders);
    throw StateError('Unexpected GET $path');
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
    final path = _path(url);
    if (path.startsWith('products/')) {
      final id = path.split('/').last;
      if (products.containsKey(id) && headers?['if-match'] == 'null_etag')
        return _response(products[id], 412);
      if (sampleWrites == failSampleAt)
        return _response({'error': 'Service unavailable'}, 503);
      products[id] = data;
      sampleWrites++;
      return _response(data);
    }
    if (path.startsWith('userfavorite/')) {
      favoriteWrites++;
      if (failFavoriteWrites) return _response({'error': 'Unavailable'}, 503);
      favorites[path.split('/').last] = data;
      return _response(data);
    }
    throw StateError('Unexpected PUT $path');
  }

  @override
  Future<http.Response> post({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final path = _path(url);
    if (path == 'products') {
      final id = 'created-product-${++productWrites}';
      products[id] = data;
      return _response({'name': id});
    }
    if (path.startsWith('order/')) {
      orderWrites++;
      orderUser = path.split('/')[1];
      placedOrder = data;
      orders['demo-order'] = data;
      return _response({'name': 'demo-order'});
    }
    throw StateError('Unexpected POST $path');
  }

  @override
  Future<http.Response> patch({
    required String url,
    Map<String, dynamic>? query,
    required Map<String, dynamic> data,
    String? token,
  }) async {
    final path = _path(url);
    if (path.startsWith('products/')) {
      final id = path.split('/').last;
      final existing = products[id];
      products[id] = {if (existing is Map) ...Map<String, dynamic>.from(existing), ...data};
      return _response(products[id]);
    }
    throw StateError('Unexpected PATCH $path');
  }

  @override
  Future<http.Response> delete({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final path = _path(url);
    if (path.startsWith('products/')) {
      products.remove(path.split('/').last);
      return _response(null);
    }
    throw StateError('Unexpected DELETE $path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected API operation');
}
