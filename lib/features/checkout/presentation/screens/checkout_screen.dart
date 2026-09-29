import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/presentation/controllers/checkout_controller.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CheckoutController>(
        builder: (context, checkout, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
            children: [
              _SectionCard(
                title: 'Delivery address',
                icon: Icons.location_on_outlined,
                trailing: TextButton(
                  onPressed: () => _editAddress(context, checkout),
                  child: Text(
                    checkout.address == null ? 'Add' : 'Change',
                  ),
                ),
                child: checkout.address == null
                    ? const _EmptySection(
                        text: 'Add an address to see delivery options.',
                      )
                    : _AddressPreview(address: checkout.address!),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Shipping',
                icon: Icons.local_shipping_outlined,
                child: checkout.address == null
                    ? const _EmptySection(
                        text: 'Shipping methods appear after you add an address.',
                      )
                    : checkout.isLoadingOptions
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _ShippingOptions(controller: checkout),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Payment',
                icon: Icons.credit_card_outlined,
                child: _PaymentOptions(controller: checkout),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Promo code',
                icon: Icons.sell_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonal(
                          onPressed: checkout.isApplyingPromo
                              ? null
                              : () {
                                  checkout.applyPromoCode(
                                    _promoController.text,
                                  );
                                },
                          child: checkout.isApplyingPromo
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Apply'),
                        ),
                      ],
                    ),
                    if (checkout.promoMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        checkout.promoMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: checkout.promoCode == null
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Order summary',
                icon: Icons.receipt_long_outlined,
                child: _OrderSummary(controller: checkout),
              ),
              if (checkout.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          checkout.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CheckoutController>(
        builder: (context, checkout, _) {
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: FilledButton(
              onPressed: checkout.canPlaceOrder
                  ? () => _placeOrder(context, checkout)
                  : null,
              child: checkout.isPlacingOrder
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Place order • \$' +
                          _formatPrice(checkout.totals.total),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editAddress(
    BuildContext context,
    CheckoutController checkout,
  ) async {
    final address = await showModalBottomSheet<CheckoutAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddressForm(
        initialAddress: checkout.address,
      ),
    );

    if (address != null) {
      await checkout.setAddress(address);
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
    CheckoutController checkout,
  ) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again before placing the order.'),
        ),
      );
      return;
    }

    final success = await checkout.placeOrder(
      userId: userId,
      accessToken: token,
    );

    if (!mounted || !success) {
      return;
    }

    context.read<CartProvider>().clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline_rounded),
        title: const Text('Order placed'),
        content: Text(
          'Order #' +
              (checkout.completedOrderId ?? '') +
              ' has been created successfully.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;

  const _EmptySection({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _AddressPreview extends StatelessWidget {
  final CheckoutAddress address;

  const _AddressPreview({
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondLine = address.addressLine2?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.fullName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(address.phone),
        const SizedBox(height: 5),
        Text(address.addressLine1),
        if (secondLine != null && secondLine.isNotEmpty) Text(secondLine),
        Text(address.city + ', ' + address.country),
      ],
    );
  }
}

class _ShippingOptions extends StatelessWidget {
  final CheckoutController controller;

  const _ShippingOptions({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.shippingMethods.isEmpty) {
      return const _EmptySection(
        text: 'No shipping methods are available for this address.',
      );
    }

    return Column(
      children: controller.shippingMethods.map((method) {
        final selected = controller.selectedShippingMethod?.id == method.id;

        return RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: method.id,
          groupValue: controller.selectedShippingMethod?.id,
          onChanged: (_) {
            controller.selectShippingMethod(method);
          },
          title: Text(
            method.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            method.description + ' • ' + method.deliveryEstimate,
          ),
          secondary: Text(
            method.price == 0
                ? 'FREE'
                : '\$' + _formatPrice(method.price),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}

class _PaymentOptions extends StatelessWidget {
  final CheckoutController controller;

  const _PaymentOptions({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.paymentMethods.isEmpty) {
      return const _EmptySection(
        text: 'Payment methods are unavailable.',
      );
    }

    return Column(
      children: controller.paymentMethods.map((method) {
        final selected = controller.selectedPaymentMethod?.id == method.id;

        return Opacity(
          opacity: method.isEnabled ? 1 : 0.55,
          child: RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: method.id,
            groupValue: controller.selectedPaymentMethod?.id,
            onChanged: method.isEnabled
                ? (_) {
                    controller.selectPaymentMethod(method);
                  }
                : null,
            title: Text(
              method.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(method.description),
            secondary: Icon(
              _paymentIcon(method.type),
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _paymentIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cashOnDelivery:
        return Icons.payments_outlined;
      case PaymentMethodType.card:
        return Icons.credit_card_outlined;
      case PaymentMethodType.digitalWallet:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _OrderSummary extends StatelessWidget {
  final CheckoutController controller;

  const _OrderSummary({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = controller.totals;

    return Column(
      children: [
        ...controller.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title +
                        ' × ' +
                        _formatQuantity(item.quantity),
                  ),
                ),
                Text('\$' + _formatPrice(item.total)),
              ],
            ),
          ),
        ),
        const Divider(height: 26),
        _SummaryRow(
          label: 'Subtotal',
          value: '\$' + _formatPrice(totals.subtotal),
        ),
        const SizedBox(height: 9),
        _SummaryRow(
          label: 'Shipping',
          value: totals.shipping == 0
              ? 'Free'
              : '\$' + _formatPrice(totals.shipping),
        ),
        if (totals.discount > 0) ...[
          const SizedBox(height: 9),
          _SummaryRow(
            label: 'Discount',
            value: '-\$' + _formatPrice(totals.discount),
          ),
        ],
        const Divider(height: 26),
        Row(
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '\$' + _formatPrice(totals.total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AddressForm extends StatefulWidget {
  final CheckoutAddress? initialAddress;

  const _AddressForm({
    this.initialAddress,
  });

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    _nameController = TextEditingController(text: address?.fullName ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _line1Controller = TextEditingController(text: address?.addressLine1 ?? '');
    _line2Controller = TextEditingController(text: address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _countryController =
        TextEditingController(text: address?.country ?? 'Egypt');
    _postalCodeController =
        TextEditingController(text: address?.postalCode ?? '');
  }

  @override
  void dispose() {
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
                'Delivery address',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 18),
              _field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(
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
              _field(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 12),
              _field(
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: const Text('Use this address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _field({
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
      CheckoutAddress(
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
      ),
    );
  }
}
