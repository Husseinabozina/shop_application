/// Storefront fixtures, independent of HTTP, Firebase, and Flutter widgets.
class SampleProduct {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final double price;
  final int stockQuantity;

  const SampleProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.stockQuantity,
  });
}

const sampleCatalog = <SampleProduct>[
  SampleProduct(
    id: 'sample-v1-chair',
    title: 'Studio stool',
    description:
        'A painted wooden stool with a compact silhouette. '
        'Use it for an extra seat or a simple side table in a calm workspace.',
    category: 'Home',
    imageUrl:
        'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=800&q=85',
    price: 149,
    stockQuantity: 12,
  ),
  SampleProduct(
    id: 'sample-v1-lamp',
    title: 'Reading light',
    description:
        'A compact lamp for late-night reading and focused desk time. '
        'A simple silhouette that fits into your everyday space.',
    category: 'Home',
    imageUrl:
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=800&q=85',
    price: 69,
    stockQuantity: 4,
  ),
  SampleProduct(
    id: 'sample-v1-mug',
    title: 'Morning mug',
    description:
        'A ceramic mug for slow mornings, coffee breaks, and your '
        'favorite tea. Comfortable to hold and easy to style on an open shelf.',
    category: 'Home',
    imageUrl:
        'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?auto=format&fit=crop&w=800&q=85',
    price: 24,
    stockQuantity: 30,
  ),
  SampleProduct(
    id: 'sample-v1-watch',
    title: 'Everyday watch',
    description:
        'A clean dial and an understated strap for an everyday '
        'accessory that works from the office to the weekend.',
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=85',
    price: 119,
    stockQuantity: 9,
  ),
  SampleProduct(
    id: 'sample-v1-bag',
    title: 'City shoulder bag',
    description:
        'A compact shoulder bag with room for your daily essentials. '
        'A versatile shape for a day in the city or an evening out.',
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=800&q=85',
    price: 89,
    stockQuantity: 3,
  ),
  SampleProduct(
    id: 'sample-v1-backpack',
    title: 'Weekend backpack',
    description:
        'An everyday carry for a light weekend trip or your commute. '
        'A practical companion for keeping the essentials close.',
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=800&q=85',
    price: 79,
    stockQuantity: 16,
  ),
  SampleProduct(
    id: 'sample-v1-sneakers',
    title: 'Weekend sneakers',
    description:
        'A bold red pair for your casual rotation. Lightweight '
        'styling for city walks and laid-back weekend plans.',
    category: 'Footwear',
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=85',
    price: 99,
    stockQuantity: 18,
  ),
  SampleProduct(
    id: 'sample-v1-headphones',
    title: 'Studio headphones',
    description:
        'Over-ear headphones for settling into your favorite '
        'playlist at home. This item is currently out of stock.',
    category: 'Audio',
    imageUrl:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=85',
    price: 129,
    stockQuantity: 0,
  ),
];
