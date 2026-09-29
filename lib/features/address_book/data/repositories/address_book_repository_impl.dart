import 'package:shop_application/features/address_book/data/datasources/address_book_remote_data_source.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';
import 'package:shop_application/features/address_book/domain/repositories/address_book_repository.dart';

class AddressBookRepositoryImpl implements AddressBookRepository {
  final AddressBookRemoteDataSource remoteDataSource;

  AddressBookRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<SavedAddress>> fetchAddresses({
    required String userId,
    required String accessToken,
  }) {
    return remoteDataSource.fetchAddresses(
      userId: userId,
      accessToken: accessToken,
    );
  }

  @override
  Future<SavedAddress> saveAddress({
    required SavedAddress address,
    required String userId,
    required String accessToken,
  }) {
    return remoteDataSource.saveAddress(
      address: address,
      userId: userId,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  }) {
    return remoteDataSource.deleteAddress(
      addressId: addressId,
      userId: userId,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
    required String accessToken,
  }) {
    return remoteDataSource.setDefaultAddress(
      addressId: addressId,
      userId: userId,
      accessToken: accessToken,
    );
  }
}
