import '../entities/saved_address.dart';

abstract class AddressBookRepository {
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
