import 'dart:convert';

import 'package:shop_application/core/firebase/firebase_rest_client.dart';
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
  final FirebaseRestClient database;

  FirebaseAddressBookRemoteDataSource({
    required this.database,
  });

  @override
  Future<List<SavedAddress>> fetchAddresses({
    required String userId,
    required String accessToken,
  }) async {
    final response = await database.get(
      path: 'addresses/$userId',
      authToken: accessToken,
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
      final response = await database.post(
        path: 'addresses/$userId',
        authToken: accessToken,
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

    final response = await database.put(
      path: 'addresses/$userId/${address.id}',
      authToken: accessToken,
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
    final response = await database.delete(
      path: 'addresses/$userId/$addressId',
      authToken: accessToken,
    );
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
      updates['${address.id}/isDefault'] = address.id == addressId;
    }

    if (updates.isEmpty) {
      return;
    }

    final response = await database.patch(
      path: 'addresses/$userId',
      authToken: accessToken,
      data: updates,
    );

    _ensureSuccess(
      response.statusCode,
      'Could not update the default address.',
    );
  }

  void _ensureSuccess(int statusCode, String message) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('$message Status $statusCode.');
    }
  }
}
