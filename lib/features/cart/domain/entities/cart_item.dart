/// An immutable cart/order line, independent of storage and Flutter.
class CartItem {
  final String? id;
  final String? title;
  final double? quantity;
  final num? price;

  const CartItem({required this.id, required this.title, this.quantity, required this.price});
}
