import 'package:flutter/foundation.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';
import 'package:shop_application/features/address_book/domain/repositories/address_book_repository.dart';

class AddressBookController with ChangeNotifier {
  final AddressBookRepository repository;

  AddressBookController({
    required this.repository,
  });

  List<SavedAddress> _addresses = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<SavedAddress> get addresses => _addresses;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  SavedAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  Future<void> load({
    required String userId,
    required String accessToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await repository.fetchAddresses(
        userId: userId,
        accessToken: accessToken,
      );
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SavedAddress?> save({
    required SavedAddress address,
    required String userId,
    required String accessToken,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shouldBecomeDefault = address.isDefault || _addresses.isEmpty;
      final saved = await repository.saveAddress(
        address: SavedAddress(
          id: address.id,
          label: address.label,
          fullName: address.fullName,
          phone: address.phone,
          addressLine1: address.addressLine1,
          addressLine2: address.addressLine2,
          city: address.city,
          country: address.country,
          postalCode: address.postalCode,
          isDefault: shouldBecomeDefault,
        ),
        userId: userId,
        accessToken: accessToken,
      );

      if (shouldBecomeDefault) {
        await repository.setDefaultAddress(
          addressId: saved.id,
          userId: userId,
          accessToken: accessToken,
        );
      }

      await load(
        userId: userId,
        accessToken: accessToken,
      );

      for (final item in _addresses) {
        if (item.id == saved.id) {
          return item;
        }
      }
      return saved;
    } catch (error) {
      _errorMessage = _cleanError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> remove({
    required String addressId,
    required String userId,
    required String accessToken,
  }) async {
    _errorMessage = null;

    try {
      final wasDefault = _addresses.any(
        (address) => address.id == addressId && address.isDefault,
      );

      await repository.deleteAddress(
        addressId: addressId,
        userId: userId,
        accessToken: accessToken,
      );

      await load(
        userId: userId,
        accessToken: accessToken,
      );

      if (wasDefault && _addresses.isNotEmpty) {
        await setDefault(
          addressId: _addresses.first.id,
          userId: userId,
          accessToken: accessToken,
        );
      }

      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefault({
    required String addressId,
    required String userId,
    required String accessToken,
  }) async {
    _errorMessage = null;

    try {
      await repository.setDefaultAddress(
        addressId: addressId,
        userId: userId,
        accessToken: accessToken,
      );

      _addresses = _addresses.map((address) {
        return SavedAddress(
          id: address.id,
          label: address.label,
          fullName: address.fullName,
          phone: address.phone,
          addressLine1: address.addressLine1,
          addressLine2: address.addressLine2,
          city: address.city,
          country: address.country,
          postalCode: address.postalCode,
          isDefault: address.id == addressId,
        );
      }).toList()
        ..sort((a, b) => a.isDefault ? -1 : (b.isDefault ? 1 : 0));

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
