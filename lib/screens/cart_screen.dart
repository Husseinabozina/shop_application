import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/features/cart/domain/services/cart_availability_validator.dart';
import 'package:shop_application/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:shop_application/widgets/cart_item.dart';
import 'package:shop_application/widgets/store_bottom_navigation.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cartScreen';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.items.entries.toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your cart'),
      ),
      body: entries.isEmpty
          ? const _EmptyCart()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final item = entry.value;

                return CartItem(
                  id: item.id,
                  productId: entry.key,
                  price: item.price,
                  title: item.title,
                  quantity: item.quantity,
                );
              },
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entries.isNotEmpty)
            _CheckoutBar(total: cart.totalPrice),
          const StoreBottomNavigation(
            selectedIndex: 2,
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatefulWidget {
  final double total;

  const _CheckoutBar({
    required this.total,
  });

  @override
  State<_CheckoutBar> createState() => _CheckoutBarState();
}

class _CheckoutBarState extends State<_CheckoutBar> {
  static const _availabilityValidator = CartAvailabilityValidator();

  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subtotal',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${_formatPrice(widget.total)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _isChecking ? null : _attemptCheckout,
              icon: _isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _isChecking ? 'Checking…' : 'Checkout',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attemptCheckout() async {
    if (_isChecking) {
      return;
    }

    setState(() => _isChecking = true);

    final productsProvider = context.read<ProductsProvider>();
    final cart = context.read<CartProvider>();

    await productsProvider.fetchProducts();

    if (!mounted) {
      return;
    }

    if (productsProvider.fetchProductsErrorMessage != null) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn’t verify product availability. Check your connection and try again.',
          ),
        ),
      );
      return;
    }

    final issues = _availabilityValidator.validate(
      cartItems: cart.items,
      products: productsProvider.products,
    );

    if (issues.isNotEmpty) {
      setState(() => _isChecking = false);
      await _showAvailabilityIssues(issues);
      return;
    }

    setState(() => _isChecking = false);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushNamed(
      CheckoutScreen.routeName,
    );
  }

  Future<void> _showAvailabilityIssues(
    List<CartAvailabilityIssue> issues,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Update your cart',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Availability changed since these items were added.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(issue.message),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Review cart'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(num value) {
    final number = value.toDouble();
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }
}
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a few products and they’ll show up here.',
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
