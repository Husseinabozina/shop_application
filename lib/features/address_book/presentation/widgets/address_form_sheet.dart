import 'package:flutter/material.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';

class AddressFormSheet extends StatefulWidget {
  final SavedAddress? initialAddress;

  const AddressFormSheet({
    super.key,
    this.initialAddress,
  });

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;

    _labelController = TextEditingController(text: address?.label ?? 'Home');
    _nameController = TextEditingController(text: address?.fullName ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _line1Controller = TextEditingController(text: address?.addressLine1 ?? '');
    _line2Controller = TextEditingController(text: address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _countryController =
        TextEditingController(text: address?.country ?? 'Egypt');
    _postalCodeController =
        TextEditingController(text: address?.postalCode ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialAddress == null
                    ? 'Add address'
                    : 'Edit address',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 18),
              _requiredField(
                controller: _labelController,
                label: 'Label',
                icon: Icons.bookmark_outline_rounded,
              ),
              const SizedBox(height: 12),
              _requiredField(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _requiredField(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _requiredField(
                controller: _line1Controller,
                label: 'Address line 1',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address line 2 (optional)',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              _requiredField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 12),
              _requiredField(
                controller: _countryController,
                label: 'Country',
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal code (optional)',
                  prefixIcon: Icon(Icons.local_post_office_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                title: const Text('Make this my default address'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _save,
                child: Text(
                  widget.initialAddress == null
                      ? 'Save address'
                      : 'Save changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _requiredField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return label + ' is required.';
        }
        return null;
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      SavedAddress(
        id: widget.initialAddress?.id ?? '',
        label: _labelController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _line1Controller.text.trim(),
        addressLine2: _line2Controller.text.trim().isEmpty
            ? null
            : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }
}
