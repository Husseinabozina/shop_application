enum OrderStatus {
  placed,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.packed:
        return 'packed';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get progressIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.packed:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  bool get isActive {
    return this != OrderStatus.delivered && this != OrderStatus.cancelled;
  }
}

OrderStatus orderStatusFromValue(Object? raw) {
  final value = raw?.toString().trim().toLowerCase();

  switch (value) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'packed':
      return OrderStatus.packed;
    case 'shipped':
    case 'dispatched':
      return OrderStatus.shipped;
    case 'out_for_delivery':
    case 'out-for-delivery':
    case 'out for delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
    case 'canceled':
      return OrderStatus.cancelled;
    case 'placed':
    case 'processing':
    default:
      return OrderStatus.placed;
  }
}

const orderTrackingSequence = <OrderStatus>[
  OrderStatus.placed,
  OrderStatus.confirmed,
  OrderStatus.packed,
  OrderStatus.shipped,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];
