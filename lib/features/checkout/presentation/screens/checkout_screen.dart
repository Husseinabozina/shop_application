import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/address_book/presentation/widgets/address_form_sheet.dart';
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
  bool _didAutoApplyAddress = false;

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
      body: Consumer2<CheckoutController, AddressBookController>(
        builder: (context, checkout, addressBook, _) {
          final defaultAddress = addressBook.defaultAddress;
          if (!_didAutoApplyAddress &&
              checkout.address == null &&
              defaultAddress != null) {
            _didAutoApplyAddress = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && checkout.address == null) {
                checkout.setAddress(defaultAddress.toCheckoutAddress());
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
            children: [
              _SectionCard(
                title: 'Delivery address',
                icon: Icons.location_on_outlined,
                trailing: TextButton(
                  onPressed: () => _chooseDeliveryAddress(context, checkout),
                  child: Text(
                    checkout.address == null ? 'Add' : 'Change',
                  ),
                ),
                child: checkout.address == null
                    ? const _EmptySection(
                        text: 'Choose a saved address or add a new delivery address.',
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

  Future<void> _chooseDeliveryAddress(
    BuildContext context,
    CheckoutController checkout,
  ) async {
    final addressBook = context.read<AddressBookController>();

    if (addressBook.addresses.isEmpty) {
      await _addAndUseAddress(context, checkout);
      return;
    }

    final choice = await showModalBottomSheet<_AddressChoice>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose delivery address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addressBook.addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final address = addressBook.addresses[index];
                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(sheetContext).pop(
                              _AddressChoice(address: address),
                            );
                          },
                          leading: Icon(
                            address.isDefault
                                ? Icons.home_rounded
                                : Icons.location_on_outlined,
                          ),
                          title: Text(
                            address.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            address.addressLine1 +
                                ', ' +
                                address.city +
                                ', ' +
                                address.country,
                          ),
                          trailing: address.isDefault
                              ? const Icon(Icons.check_circle_rounded)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(
                      const _AddressChoice(addNew: true),
                    );
                  },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add new address'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !context.mounted) {
      return;
    }

    if (choice.addNew) {
      await _addAndUseAddress(context, checkout);
      return;
    }

    final selected = choice.address;
    if (selected != null) {
      await checkout.setAddress(selected.toCheckoutAddress());
    }
  }

  Future<void> _addAndUseAddress(
    BuildContext context,
    CheckoutController checkout,
  ) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    if (token == null || userId == null) {
      return;
    }

    final address = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddressFormSheet(),
    );

    if (address == null || !context.mounted) {
      return;
    }

    final saved = await context.read<AddressBookController>().save(
          address: address,
          userId: userId,
          accessToken: token,
        );

    if (saved != null && context.mounted) {
      await checkout.setAddress(saved.toCheckoutAddress());
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

    if (!context.mounted || !success) {
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

    if (context.mounted) {
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
        Text('${address.city}, ${address.country}'),
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

    return RadioGroup<String>(
      groupValue: controller.selectedShippingMethod?.id,
      onChanged: (methodId) {
        if (methodId == null) {
          return;
        }

        final method = controller.shippingMethods.firstWhere(
          (item) => item.id == methodId,
        );
        controller.selectShippingMethod(method);
      },
      child: Column(
        children: controller.shippingMethods.map((method) {
          final selected =
              controller.selectedShippingMethod?.id == method.id;

          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: method.id,
            title: Text(
              method.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${method.description} • ${method.deliveryEstimate}',
            ),
            secondary: Text(
              method.price == 0
                  ? 'FREE'
                  : '\$${_formatPrice(method.price)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
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

    return RadioGroup<String>(
      groupValue: controller.selectedPaymentMethod?.id,
      onChanged: (methodId) {
        if (methodId == null) {
          return;
        }

        final method = controller.paymentMethods.firstWhere(
          (item) => item.id == methodId,
        );

        if (method.isEnabled) {
          controller.selectPaymentMethod(method);
        }
      },
      child: Column(
        children: controller.paymentMethods.map((method) {
          final selected =
              controller.selectedPaymentMethod?.id == method.id;

          return Opacity(
            opacity: method.isEnabled ? 1 : 0.55,
            child: RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: method.id,
              enabled: method.isEnabled,
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
      ),
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

class _AddressChoice {
  final SavedAddress? address;
  final bool addNew;

  const _AddressChoice({
    this.address,
    this.addNew = false,
  });
}
