import 'package:flutter/material.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/provider/order.dart';

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
    if (token == null || userId == null) {
      fetchOrdersErrorMessage = 'Please sign in again.';
      notifyListeners();
      return;
    }

    final result = await orderRepo.fetchOrders(userId!, token!);
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

  Future<void> fetchOrder(String orderId) async {
    final result = await orderRepo.fetchOrder(orderId, token);
    result.when(
      success: (order) {
        _order = order;
        fetchOrderErrorMessage = null;
        notifyListeners();
      },
      failure: (error) {
        fetchOrderErrorMessage = error.message;
        notifyListeners();
      },
    );
  }

  Future<bool> addOrder({
    required double amount,
    required List<CartModel> products,
  }) async {
    if (token == null || userId == null) {
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
      userId: userId,
      token: token,
    );

    var wasSuccessful = false;
    result.when(
      success: (_) {
        _orders.insert(0, order);
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
