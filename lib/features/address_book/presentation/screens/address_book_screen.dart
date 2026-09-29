import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/auth_provider/auth_provider.dart';
import 'package:shop_application/features/address_book/domain/entities/saved_address.dart';
import 'package:shop_application/features/address_book/presentation/controllers/address_book_controller.dart';
import 'package:shop_application/features/address_book/presentation/widgets/address_form_sheet.dart';
import 'package:shop_application/widgets/app_drawer.dart';

class AddressBookScreen extends StatelessWidget {
  static const routeName = '/addresses';

  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddressBookController>();
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Saved addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add address'),
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading && controller.addresses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.errorMessage != null &&
              controller.addresses.isEmpty) {
            return _AddressErrorState(
              message: controller.errorMessage!,
              onRetry: () => _reload(context),
            );
          }

          if (controller.addresses.isEmpty) {
            return const _EmptyAddressBook();
          }

          return RefreshIndicator(
            onRefresh: () => _reload(context),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              itemCount: controller.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final address = controller.addresses[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _iconFor(address.label),
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          address.label,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            'Default',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    address.fullName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openAddressForm(
                                    context,
                                    initialAddress: address,
                                  );
                                } else if (value == 'default') {
                                  _setDefault(context, address);
                                } else if (value == 'delete') {
                                  _deleteAddress(context, address);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (!address.isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Make default'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(address.phone),
                        const SizedBox(height: 5),
                        Text(address.addressLine1),
                        if ((address.addressLine2 ?? '').trim().isNotEmpty)
                          Text(address.addressLine2!),
                        Text(address.city + ', ' + address.country),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _reload(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    if (token == null || userId == null) {
      return;
    }

    await context.read<AddressBookController>().load(
          userId: userId,
          accessToken: token,
        );
  }

  Future<void> _openAddressForm(
    BuildContext context, {
    SavedAddress? initialAddress,
  }) async {
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
      builder: (_) => AddressFormSheet(
        initialAddress: initialAddress,
      ),
    );

    if (address == null || !context.mounted) {
      return;
    }

    await context.read<AddressBookController>().save(
          address: address,
          userId: userId,
          accessToken: token,
        );
  }

  Future<void> _setDefault(
    BuildContext context,
    SavedAddress address,
  ) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    if (token == null || userId == null) {
      return;
    }

    await context.read<AddressBookController>().setDefault(
          addressId: address.id,
          userId: userId,
          accessToken: token,
        );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(
          'Remove ' + address.label + ' from your saved addresses?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;

    if (token == null || userId == null) {
      return;
    }

    await context.read<AddressBookController>().remove(
          addressId: address.id,
          userId: userId,
          accessToken: token,
        );
  }

  IconData _iconFor(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.contains('work') || normalized.contains('office')) {
      return Icons.work_outline_rounded;
    }
    return Icons.home_outlined;
  }
}

class _EmptyAddressBook extends StatelessWidget {
  const _EmptyAddressBook();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 58,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved addresses yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a delivery address once and reuse it at checkout.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AddressErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
