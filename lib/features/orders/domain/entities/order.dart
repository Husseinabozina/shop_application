import 'package:shop_application/features/cart/domain/entities/cart_item.dart';
import 'package:shop_application/features/orders/domain/entities/order_status.dart';

class Order {
  final String? id;
  final DateTime? datetime;
  final double? amount;
  final String currency;
  final String? sandboxInvoiceId;
  final List<CartItem>? products;
  final OrderStatus status;
  final String? paymentStatus;
  final String? paymentMethodTitle;
  final String? shippingMethodTitle;
  final int? shippingMinDays;
  final int? shippingMaxDays;
  final DateTime? estimatedDeliveryStart;
  final DateTime? estimatedDeliveryEnd;
  final Map<OrderStatus, DateTime> statusHistory;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;

  const Order({
    this.id,
    this.datetime,
    this.amount,
    this.currency = 'USD',
    this.sandboxInvoiceId,
    this.products,
    this.status = OrderStatus.placed,
    this.paymentStatus,
    this.paymentMethodTitle,
    this.shippingMethodTitle,
    this.shippingMinDays,
    this.shippingMaxDays,
    this.estimatedDeliveryStart,
    this.estimatedDeliveryEnd,
    this.statusHistory = const {},
    this.recipientName,
    this.recipientPhone,
    this.deliveryAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datetime': datetime?.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'products': products
          ?.map(
            (product) => {
              'id': product.id,
              'title': product.title,
              'quantity': product.quantity,
              'price': product.price,
            },
          )
          .toList(),
      'status': status.value,
      'paymentStatus': paymentStatus,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final shippingMethod = _asMap(json['shippingMethod']);
    final paymentMethod = _asMap(json['paymentMethod']);
    final shippingAddress = _asMap(json['shippingAddress']);
    final parsedStatus = orderStatusFromValue(json['status']);
    final orderDate = _parseDate(json['datetime']);

    final minDays = _parseInt(shippingMethod?['minDeliveryDays']);
    final maxDays = _parseInt(shippingMethod?['maxDeliveryDays']);

    final start =
        _parseDate(json['estimatedDeliveryStart']) ??
        (orderDate != null && minDays != null
            ? orderDate.add(Duration(days: minDays))
            : null);
    final end =
        _parseDate(json['estimatedDeliveryEnd']) ??
        (orderDate != null && maxDays != null
            ? orderDate.add(Duration(days: maxDays))
            : null);

    return Order(
      id: json['id']?.toString(),
      datetime: orderDate,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'USD',
      sandboxInvoiceId: _asMap(
        json['sandboxPayment'],
      )?['invoiceId']?.toString(),
      products: _parseProducts(json['products']),
      status: parsedStatus,
      paymentStatus: json['paymentStatus']?.toString(),
      paymentMethodTitle: paymentMethod?['title']?.toString(),
      shippingMethodTitle: shippingMethod?['title']?.toString(),
      shippingMinDays: minDays,
      shippingMaxDays: maxDays,
      estimatedDeliveryStart: start,
      estimatedDeliveryEnd: end,
      statusHistory: _parseStatusHistory(
        json['statusHistory'],
        fallbackStatus: parsedStatus,
        fallbackDate: orderDate,
      ),
      recipientName: shippingAddress?['fullName']?.toString(),
      recipientPhone: shippingAddress?['phone']?.toString(),
      deliveryAddress: _formatAddress(shippingAddress),
    );
  }

  static List<CartItem>? _parseProducts(Object? raw) {
    if (raw is! List) {
      return null;
    }

    return raw
        .whereType<Map>()
        .map(
          (product) => CartItem(
            id: product['id'] as String?,
            title: product['title'] as String?,
            quantity: ((product['quantity'] ?? product['quantitiy']) as num?)
                ?.toDouble(),
            price: product['price'] as num?,
          ),
        )
        .toList();
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(raw);
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }

  static int? _parseInt(Object? raw) {
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  static Map<OrderStatus, DateTime> _parseStatusHistory(
    Object? raw, {
    required OrderStatus fallbackStatus,
    required DateTime? fallbackDate,
  }) {
    final history = <OrderStatus, DateTime>{};

    if (raw is Map) {
      for (final entry in raw.entries) {
        final date = _parseDate(entry.value);
        if (date != null) {
          history[orderStatusFromValue(entry.key)] = date;
        }
      }
    }

    if (history.isEmpty && fallbackDate != null) {
      history[fallbackStatus] = fallbackDate;
    }

    return history;
  }

  static String? _formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return null;
    }

    final parts = [
      address['addressLine1']?.toString(),
      address['addressLine2']?.toString(),
      address['city']?.toString(),
      address['country']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    final value = parts.join(', ');
    return value.isEmpty ? null : value;
  }
}
