import 'dart:convert';

import 'package:shop_application/core/network/api.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';

abstract class AddressBookRemoteDataSource {
  Future<List<SavedAddress>> fetchAddresses({
    required String userId,
    required String accessToken,
  });

  Future<SavedAddress> saveAddress({
    required SavedAddress address,
    required String userId,
    required String accessToken,
  });

  Future<void> deleteAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  });

  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  });
}

class FirebaseAddressBookRemoteDataSource
    implements AddressBookRemoteDataSource {
  final Api api;

  FirebaseAddressBookRemoteDataSource({
    required this.api,
  });

  String _baseUrl({
    required String userId,
    required String accessToken,
  }) {
    return 'https://shopapp-29118-default-rtdb.firebaseio.com/addresses/' +
        userId +
        '.json?auth=' +
        accessToken;
  }

  @override
  Future<List<SavedAddress>> fetchAddresses({
    required String userId,
    required String accessToken,
  }) async {
    final response = await api.get(
      url: _baseUrl(
        userId: userId,
        accessToken: accessToken,
      ),
    );

    _ensureSuccess(response.statusCode, 'Could not load addresses.');

    final decoded = json.decode(response.body);
    if (decoded == null) {
      return const [];
    }

    final data = decoded as Map<String, dynamic>;
    final addresses = data.entries.map((entry) {
      return SavedAddress.fromJson(
        id: entry.key,
        json: Map<String, dynamic>.from(entry.value as Map),
      );
    }).toList()
      ..sort((a, b) {
        if (a.isDefault == b.isDefault) {
          return a.label.compareTo(b.label);
        }
        return a.isDefault ? -1 : 1;
      });

    return addresses;
  }

  @override
  Future<SavedAddress> saveAddress({
    required SavedAddress address,
    required String userId,
    required String accessToken,
  }) async {
    if (address.id.isEmpty) {
      final response = await api.post(
        url: _baseUrl(
          userId: userId,
          accessToken: accessToken,
        ),
        data: address.toJson(),
      );

      _ensureSuccess(response.statusCode, 'Could not save address.');

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final id = decoded['name']?.toString();

      if (id == null || id.isEmpty) {
        throw Exception('Address was saved without an id.');
      }

      return SavedAddress(
        id: id,
        label: address.label,
        fullName: address.fullName,
        phone: address.phone,
        addressLine1: address.addressLine1,
        addressLine2: address.addressLine2,
        city: address.city,
        country: address.country,
        postalCode: address.postalCode,
        isDefault: address.isDefault,
      );
    }

    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/addresses/' +
            userId +
            '/' +
            address.id +
            '.json?auth=' +
            accessToken;

    final response = await api.put(
      url: url,
      data: address.toJson(),
    );

    _ensureSuccess(response.statusCode, 'Could not update address.');
    return address;
  }

  @override
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  }) async {
    final url =
        'https://shopapp-29118-default-rtdb.firebaseio.com/addresses/' +
            userId +
            '/' +
            addressId +
            '.json?auth=' +
            accessToken;

    final response = await api.delete(url: url);
    _ensureSuccess(response.statusCode, 'Could not delete address.');
  }

  @override
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  }) async {
    final addresses = await fetchAddresses(
      userId: userId,
      accessToken: accessToken,
    );

    final updates = <String, dynamic>{};
    for (final address in addresses) {
      updates[address.id + '/isDefault'] = address.id == addressId;
    }

    if (updates.isEmpty) {
      return;
    }

    final response = await api.patch(
      url: _baseUrl(
        userId: userId,
        accessToken: accessToken,
      ),
      data: updates,
    );

    _ensureSuccess(
      response.statusCode,
      'Could not update the default address.',
    );
  }

  void _ensureSuccess(int statusCode, String message) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(message + ' Status ' + statusCode.toString() + '.');
    }
  }
}
