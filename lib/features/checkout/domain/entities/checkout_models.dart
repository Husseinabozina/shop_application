enum PaymentMethodType {
  cashOnDelivery,
  card,
  digitalWallet,
}

class CheckoutAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String country;
  final String? postalCode;

  const CheckoutAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.country,
    this.postalCode,
  });

  bool get isComplete {
    return fullName.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        addressLine1.trim().isNotEmpty &&
        city.trim().isNotEmpty &&
        country.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'country': country,
      'postalCode': postalCode,
    };
  }
}

class CheckoutLineItem {
  final String productId;
  final String title;
  final double quantity;
  final num unitPrice;

  const CheckoutLineItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice.toDouble() * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class ShippingMethod {
  final String id;
  final String title;
  final String description;
  final double price;
  final int minDeliveryDays;
  final int maxDeliveryDays;

  const ShippingMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.minDeliveryDays,
    required this.maxDeliveryDays,
  });

  String get deliveryEstimate {
    if (minDeliveryDays == maxDeliveryDays) {
      return minDeliveryDays.toString() + ' day delivery';
    }
    return minDeliveryDays.toString() +
        '–' +
        maxDeliveryDays.toString() +
        ' business days';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'minDeliveryDays': minDeliveryDays,
      'maxDeliveryDays': maxDeliveryDays,
    };
  }
}

class PaymentMethodOption {
  final String id;
  final PaymentMethodType type;
  final String title;
  final String description;
  final bool isEnabled;

  const PaymentMethodOption({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
    };
  }
}

class PromoCodeResult {
  final String code;
  final double discountAmount;
  final bool freeShipping;
  final String message;

  const PromoCodeResult({
    required this.code,
    required this.discountAmount,
    required this.freeShipping,
    required this.message,
  });
}

class CheckoutTotals {
  final double subtotal;
  final double shipping;
  final double discount;

  const CheckoutTotals({
    required this.subtotal,
    required this.shipping,
    required this.discount,
  });

  double get total {
    final value = subtotal + shipping - discount;
    return value < 0 ? 0 : value;
  }
}

class CheckoutOrderDraft {
  final List<CheckoutLineItem> items;
  final CheckoutAddress address;
  final ShippingMethod shippingMethod;
  final PaymentMethodOption paymentMethod;
  final CheckoutTotals totals;
  final String? promoCode;

  const CheckoutOrderDraft({
    required this.items,
    required this.address,
    required this.shippingMethod,
    required this.paymentMethod,
    required this.totals,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    final placedAt = DateTime.now();
    final estimatedDeliveryStart = placedAt.add(
      Duration(days: shippingMethod.minDeliveryDays),
    );
    final estimatedDeliveryEnd = placedAt.add(
      Duration(days: shippingMethod.maxDeliveryDays),
    );

    return {
      'items': items.map((item) => item.toJson()).toList(),
      'shippingAddress': address.toJson(),
      'shippingMethod': shippingMethod.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'promoCode': promoCode,
      'subtotal': totals.subtotal,
      'shippingAmount': totals.shipping,
      'discountAmount': totals.discount,
      'amount': totals.total,
      'datetime': placedAt.toIso8601String(),
      'status': 'placed',
      'statusHistory': {
        'placed': placedAt.toIso8601String(),
      },
      'estimatedDeliveryStart': estimatedDeliveryStart.toIso8601String(),
      'estimatedDeliveryEnd': estimatedDeliveryEnd.toIso8601String(),
      'paymentStatus':
          paymentMethod.type == PaymentMethodType.cashOnDelivery
              ? 'cash_on_delivery'
              : 'pending',
      'products': items
          .map(
            (item) => {
              'id': item.productId,
              'title': item.title,
              'quantity': item.quantity,
              'price': item.unitPrice,
            },
          )
          .toList(),
    };
  }
}

class CheckoutResult {
  final String orderId;

  const CheckoutResult({
    required this.orderId,
  });
}
