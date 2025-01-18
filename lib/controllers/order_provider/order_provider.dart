import 'package:flutter/material.dart';
import 'package:shop_application/core/network/api_result.dart';
import 'package:shop_application/data/models/cart/cart_model.dart';
import 'package:shop_application/data/repos/order_repo.dart';
import 'package:shop_application/provider/order.dart';
import 'package:shop_application/provider/product.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepo orderRepo;
  final String? token;
  final String? userId;
  OrderProvider({required this.orderRepo, this.token, this.userId});
  List<Order>? _orders;

  List<Order>? get orders => _orders;

  String? fetchOrdersErrorMessage;
  String? fetchOrderErrorMessage;
  String? addOrderErrorMessage;

  Future<void> fetchOrders() async {
    final result = await orderRepo.fetchOrders(token!);
    result.when(
      success: (orders) {
        _orders = orders;
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
        notifyListeners();
      },
      failure: (error) {
        fetchOrderErrorMessage = error.message;
        notifyListeners();
      },
    );
  }

  Future<void> addOrder(
      {required double amount, required List<CartModel> products}) async {
    final timesTamp = DateTime.now();
    final result = await orderRepo.addOrder(
        order: Order(datetime: timesTamp, amount: amount, products: products),
        userId: userId,
        token: token);
    result.when(success: (order) {
      notifyListeners();
    }, failure: (error) {
      addOrderErrorMessage = error.message;
      notifyListeners();
    });
  }
}
