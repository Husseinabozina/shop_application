import 'package:flutter_test/flutter_test.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';

void main() {
  test('maps saved address into checkout address', () {
    const saved = SavedAddress(
      id: 'address-1',
      label: 'Home',
      fullName: 'Test User',
      phone: '01000000000',
      addressLine1: 'Main Street',
      addressLine2: 'Apartment 4',
      city: 'Cairo',
      country: 'Egypt',
      postalCode: '12345',
      isDefault: true,
    );

    final checkout = saved.toCheckoutAddress();

    expect(checkout.fullName, 'Test User');
    expect(checkout.phone, '01000000000');
    expect(checkout.addressLine1, 'Main Street');
    expect(checkout.city, 'Cairo');
    expect(checkout.country, 'Egypt');
    expect(checkout.isComplete, isTrue);
  });

  test('parses Firebase address metadata safely', () {
    final address = SavedAddress.fromJson(
      id: 'address-2',
      json: {
        'label': 'Work',
        'fullName': 'Test User',
        'phone': '01000000000',
        'addressLine1': 'Business Park',
        'city': 'New Cairo',
        'country': 'Egypt',
        'isDefault': false,
      },
    );

    expect(address.id, 'address-2');
    expect(address.label, 'Work');
    expect(address.isDefault, isFalse);
  });
}
