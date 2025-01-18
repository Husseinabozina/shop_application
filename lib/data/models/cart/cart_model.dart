class CartModel {
  final String? id;
  final String? title;
  final double? quantity; // Fixed the typo from "quantitiy" to "quantity"
  final num? price;

  CartModel({
    required this.id,
    required this.title,
    this.quantity,
    required this.price,
  });

  /// Convert a CartModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'price': price,
    };
  }

  /// Create a CartModel instance from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as String?,
      title: json['title'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      price: json['price'] as num?,
    );
  }
}
