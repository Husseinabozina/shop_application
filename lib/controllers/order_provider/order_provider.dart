import 'package:flutter/material.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/features/orders/domain/entities/order.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepo orderRepo;
  final String? token;
  final String? userId;

  OrderProvider({
    required this.orderRepo,
    this.token,
    this.userId,
  });

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  String? fetchOrdersErrorMessage;
  String? fetchOrderErrorMessage;
  String? addOrderErrorMessage;

  Future<void> fetchOrders() async {
    final accessToken = token;
    final activeUserId = userId;

    if (accessToken == null || activeUserId == null) {
      fetchOrdersErrorMessage = 'Please sign in again.';
      notifyListeners();
      return;
    }

    final result = await orderRepo.fetchOrders(
      activeUserId,
      accessToken,
    );

    result.when(
      success: (orders) {
        _orders = orders;
        fetchOrdersErrorMessage = null;
        notifyListeners();
      },
      failure: (error) {
        fetchOrdersErrorMessage = error.message;
        notifyListeners();
      },
    );
  }

  Order? _order;
  Order? get order => _order;

  Future<Order?> fetchOrder(String orderId) async {
    final accessToken = token;
    final activeUserId = userId;

    if (accessToken == null || activeUserId == null) {
      fetchOrderErrorMessage = 'Please sign in again.';
      notifyListeners();
      return null;
    }

    final result = await orderRepo.fetchOrder(
      userId: activeUserId,
      orderId: orderId,
      token: accessToken,
    );

    Order? loadedOrder;
    result.when(
      success: (order) {
        _order = order;
        loadedOrder = order;
        fetchOrderErrorMessage = null;

        final index = _orders.indexWhere((item) => item.id == order.id);
        if (index >= 0) {
          _orders[index] = order;
        }

        notifyListeners();
      },
      failure: (error) {
        fetchOrderErrorMessage = error.message;
        notifyListeners();
      },
    );

    return loadedOrder;
  }

  Future<bool> addOrder({
    required double amount,
    required List<CartModel> products,
  }) async {
    final accessToken = token;
    final activeUserId = userId;

    if (accessToken == null || activeUserId == null) {
      addOrderErrorMessage = 'Please sign in again.';
      notifyListeners();
      return false;
    }

    final timestamp = DateTime.now();
    final order = Order(
      datetime: timestamp,
      amount: amount,
      products: products,
    );

    final result = await orderRepo.addOrder(
      order: order,
      userId: activeUserId,
      token: accessToken,
    );

    var wasSuccessful = false;
    result.when(
      success: (response) {
        _orders.insert(
          0,
          Order(
            id: response.name,
            datetime: order.datetime,
            amount: order.amount,
            products: order.products,
          ),
        );
        addOrderErrorMessage = null;
        wasSuccessful = true;
        notifyListeners();
      },
      failure: (error) {
        addOrderErrorMessage = error.message;
        notifyListeners();
      },
    );

    return wasSuccessful;
  }
}
