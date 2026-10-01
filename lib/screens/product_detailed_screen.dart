import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/cart/presentation/controllers/cart_controller.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/features/catalog/presentation/controllers/recently_viewed_controller.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';

class ProductDetailedScreen extends StatefulWidget {
  static const routeName = '/ProductDetailed';

  const ProductDetailedScreen({super.key});

  @override
  State<ProductDetailedScreen> createState() => _ProductDetailedScreenState();
}

class _ProductDetailedScreenState extends State<ProductDetailedScreen> {
  String? _productId;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    _productId = productId;
    Product product;
    try {
      product = context.read<CatalogController>().findById(productId);
    } on StateError {
      return;
    }

    final canonicalId = product.id ?? product.productId;
    if (canonicalId != null) {
      unawaited(
        Future<void>.microtask(() {
          if (mounted) {
            return context.read<RecentlyViewedController>().record(canonicalId);
          }
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = _productId;
    if (productId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final catalog = context.watch<CatalogController>();
    Product product;
    try {
      product = catalog.findById(productId);
    } on StateError {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This product is no longer available.')),
      );
    }
    return Provider<Product>.value(
      value: product,
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = context.watch<Product>();
    final heroTag = product.id ?? product.productId ?? product.title ?? '';

    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: FilledButton.icon(
          onPressed: product.isInStock
              ? () => _addToCart(context, product)
              : null,
          icon: Icon(
            product.isInStock
                ? Icons.shopping_bag_outlined
                : Icons.block_rounded,
          ),
          label: Text(
            product.isInStock ? 'Add to cart' : 'Sold out',
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 420,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  tooltip: product.isFavorite
                      ? 'Remove from saved'
                      : 'Save product',
                  onPressed: context.watch<CatalogController>().isFavoritePending(
                    product.productId ?? product.id ?? '',
                  ) ? null : () => _toggleFavorite(context, product),
                  icon: Icon(
                    product.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: product.isFavorite
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: _ProductGallery(
                  imageUrls: product.imageUrls,
                  fallbackColor:
                      theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      product.category,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StockStatusChip(product: product),
                  const SizedBox(height: 12),
                  Text(
                    product.title ?? 'Untitled product',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${_formatPrice(product.price)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description?.trim().isNotEmpty == true
                        ? product.description!
                        : 'No description is available for this product yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _InfoCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery options',
                    description:
                        'Standard delivery in 3–5 business days, or Express in 1–2 days at checkout.',
                  ),
                  const SizedBox(height: 12),
                  const _InfoCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Secure shopping',
                    description:
                        'Your saved items, cart, delivery details, and order history stay tied to your account.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Product product,
  ) async {
    final id = product.productId ?? product.id;
    if (id == null) return;
    final catalog = context.read<CatalogController>();
    final saved = await catalog.toggleFavorite(id);
    if (!context.mounted || saved) return;
    final error = catalog.favoriteError(id);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _addToCart(
    BuildContext context,
    Product product,
  ) {
    if (!product.isInStock ||
        product.id == null ||
        product.price == null ||
        product.title == null) {
      return;
    }

    final added = context.read<CartController>().addItem(
          product.id!,
          product.price!,
          product.title!,
          maxQuantity: product.stockQuantity?.toDouble(),
        );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${product.title!} added to cart'
                : 'Maximum available stock is already in your cart',
          ),
        ),
      );
  }

  String _formatPrice(num? price) {
    final value = price?.toDouble() ?? 0;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}



class _ProductGallery extends StatefulWidget {
  final List<String> imageUrls;
  final Color fallbackColor;

  const _ProductGallery({
    required this.imageUrls,
    required this.fallbackColor,
  });

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _ImageFallback(
        color: widget.fallbackColor,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (_, index) {
            return Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ImageFallback(
                color: widget.fallbackColor,
              ),
            );
          },
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _currentIndex ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StockStatusChip extends StatelessWidget {
  final Product product;

  const _StockStatusChip({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOut = !product.isInStock;
    final isLow = product.isLowStock;

    final background = isOut
        ? theme.colorScheme.errorContainer
        : isLow
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceContainerHigh;

    final foreground = isOut
        ? theme.colorScheme.onErrorContainer
        : isLow
            ? theme.colorScheme.onTertiaryContainer
            : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOut
                  ? Icons.block_rounded
                  : isLow
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
              size: 16,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Text(
              product.stockLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    require…901 tokens truncated…                   ),
                        ),
                        Text(
                          'Your storefront',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.storefront_outlined,
              label: 'Shop',
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
            _DrawerTile(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              onTap: () {
                Navigator.of(context)
                    .pushReplacementNamed(OrdersScreen.routeName);
              },
            ),
            _DrawerTile(
              icon: Icons.location_on_outlined,
              label: 'Saved addresses',
              onTap: () {
                Navigator.of(context)
                    .pushReplacementNamed(AddressBookScreen.routeName);
              },
            ),
            _DrawerTile(
              icon: Icons.inventory_2_outlined,
              label: 'Manage products',
              onTap: () {
                Navigator.of(context)
                    .pushReplacementNamed(UserProductScreen.routeName);
              },
            ),
            const Spacer(),
            const Divider(),
            _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              danger: true,
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthController>().logOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        danger ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Icon(icon, color: foreground),
        title: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
