import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/cart_provider/cart_provider.dart';
import 'package:shop_application/controllers/order_provider/order_provider.dart';
import 'package:shop_application/widgets/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routName = '/cartScreen';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final entries = cart.Items.entries.toList();

    return Scaffold(
      appBar: AppBar(
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
      bottomNavigationBar: entries.isEmpty
          ? null
          : _CheckoutBar(
              total: cart.totalPrice,
              cart: cart,
            ),
    );
  }
}

class _CheckoutBar extends StatefulWidget {
  final double total;
  final CartProvider cart;

  const _CheckoutBar({
    required this.total,
    required this.cart,
  });

  @override
  State<_CheckoutBar> createState() => _CheckoutBarState();
}

class _CheckoutBarState extends State<_CheckoutBar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                    'Total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$' + _formatPrice(widget.total),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _placeOrder,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(_isLoading ? 'Placing...' : 'Place order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.addOrder(
      products: widget.cart.Items.values.toList(),
      amount: widget.cart.totalPrice,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (success) {
      widget.cart.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          orderProvider.addOrderErrorMessage ??
              'Could not place your order. Please try again.',
        ),
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
