import 'package:flutter/foundation.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';
import 'package:shop_application/features/orders/domain/repositories/order_repository.dart';

class OrderController with ChangeNotifier {
  final OrderRepository repository;
  final String? token;
  final String? userId;

  OrderController({
    required this.repository,
    this.token,
    this.userId,
  });

  List<Order> _orders = const [];
  List<Order> get orders => _orders;

  Order? _focusedOrder;
  Order? get focusedOrder => _focusedOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? fetchOrdersErrorMessage;
  String? fetchOrderErrorMessage;

  Future<void> fetchOrders() async {
    final accessToken = token;
    final activeUserId = userId;

    if (accessToken == null || activeUserId == null) {
      fetchOrdersErrorMessage = 'Please sign in again.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    fetchOrdersErrorMessage = null;
    notifyListeners();

    try {
      _orders = await repository.fetchOrders(
        userId: activeUserId,
        accessToken: accessToken,
      );
    } catch (error) {
      fetchOrdersErrorMessage = _cleanError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> fetchOrder(String orderId) async {
    final accessToken = token;
    final activeUserId = userId;

    if (accessToken == null || activeUserId == null) {
      fetchOrderErrorMessage = 'Please sign in again.';
      notifyListeners();
      return null;
    }

    fetchOrderErrorMessage = null;

    try {
      final order = await repository.fetchOrder(
        userId: activeUserId,
        orderId: orderId,
        accessToken: accessToken,
      );

      _focusedOrder = order;

      final index = _orders.indexWhere((item) => item.id == order.id);
      if (index >= 0) {
        final updated = List<Order>.from(_orders);
        updated[index] = order;
        _orders = updated;
      }

      notifyListeners();
      return order;
    } catch (error) {
      fetchOrderErrorMessage = _cleanError(error);
      notifyListeners();
      return null;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
