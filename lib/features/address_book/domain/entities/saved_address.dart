import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';

class SavedAddress {
  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String country;
  final String? postalCode;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.country,
    this.postalCode,
    this.isDefault = false,
  });

  CheckoutAddress toCheckoutAddress() {
    return CheckoutAddress(
      fullName: fullName,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      country: country,
      postalCode: postalCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  factory SavedAddress.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return SavedAddress(
      id: id,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? json['label'] as String
          : 'Address',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      postalCode: json['postalCode'] as String?,
      isDefault: json['isDefault'] == true,
    );
  }
}
