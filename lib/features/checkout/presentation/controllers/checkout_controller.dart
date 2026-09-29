import 'package:flutter/foundation.dart';
import 'package:shop_application/features/checkout/domain/entities/checkout_models.dart';
import 'package:shop_application/features/checkout/domain/repositories/checkout_repository.dart';

class CheckoutController with ChangeNotifier {
  final CheckoutRepository repository;

  CheckoutController({
    required this.repository,
  });

  List<CheckoutLineItem> _items = const [];
  CheckoutAddress? _address;
  List<ShippingMethod> _shippingMethods = const [];
  ShippingMethod? _selectedShippingMethod;
  List<PaymentMethodOption> _paymentMethods = const [];
  PaymentMethodOption? _selectedPaymentMethod;
  PromoCodeResult? _promoCode;
  bool _isLoadingOptions = false;
  bool _isApplyingPromo = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;
  String? _promoMessage;
  String? _completedOrderId;

  List<CheckoutLineItem> get items => _items;
  CheckoutAddress? get address => _address;
  List<ShippingMethod> get shippingMethods => _shippingMethods;
  ShippingMethod? get selectedShippingMethod => _selectedShippingMethod;
  List<PaymentMethodOption> get paymentMethods => _paymentMethods;
  PaymentMethodOption? get selectedPaymentMethod => _selectedPaymentMethod;
  PromoCodeResult? get promoCode => _promoCode;
  bool get isLoadingOptions => _isLoadingOptions;
  bool get isApplyingPromo => _isApplyingPromo;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get errorMessage => _errorMessage;
  String? get promoMessage => _promoMessage;
  String? get completedOrderId => _completedOrderId;

  double get subtotal {
    return _items.fold<double>(
      0,
      (total, item) => total + item.total,
    );
  }

  CheckoutTotals get totals {
    final shipping = _promoCode?.freeShipping == true
        ? 0.0
        : (_selectedShippingMethod?.price ?? 0.0);

    return CheckoutTotals(
      subtotal: subtotal,
      shipping: shipping,
      discount: _promoCode?.discountAmount ?? 0.0,
    );
  }

  bool get canPlaceOrder {
    return _items.isNotEmpty &&
        _address?.isComplete == true &&
        _selectedShippingMethod != null &&
        _selectedPaymentMethod?.isEnabled == true &&
        !_isPlacingOrder;
  }

  Future<void> initialize({
    required List<CheckoutLineItem> items,
  }) async {
    _items = List.unmodifiable(items);
    _errorMessage = null;

    try {
      _paymentMethods = await repository.getPaymentMethods();
      _selectedPaymentMethod = _paymentMethods.cast<PaymentMethodOption?>().firstWhere(
            (method) => method?.isEnabled == true,
            orElse: () => null,
          );
    } catch (error) {
      _errorMessage = _cleanError(error);
    }

    notifyListeners();
  }

  Future<void> setAddress(CheckoutAddress address) async {
    _address = address;
    _isLoadingOptions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shippingMethods = await repository.getShippingMethods(
        address: address,
        items: _items,
      );
      _selectedShippingMethod =
          _shippingMethods.isEmpty ? null : _shippingMethods.first;
    } catch (error) {
      _shippingMethods = const [];
      _selectedShippingMethod = null;
      _errorMessage = _cleanError(error);
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  void selectShippingMethod(ShippingMethod method) {
    _selectedShippingMethod = method;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethodOption method) {
    if (!method.isEnabled) {
      return;
    }
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<void> applyPromoCode(String code) async {
    if (code.trim().isEmpty) {
      _promoCode = null;
      _promoMessage = null;
      notifyListeners();
      return;
    }

    _isApplyingPromo = true;
    _promoMessage = null;
    notifyListeners();

    try {
      _promoCode = await repository.applyPromoCode(
        code: code,
        subtotal: subtotal,
      );
      _promoMessage = _promoCode?.message;
    } catch (error) {
      _promoCode = null;
      _promoMessage = _cleanError(error);
    } finally {
      _isApplyingPromo = false;
      notifyListeners();
    }
  }

  Future<bool> placeOrder({
    required String userId,
    required String accessToken,
  }) async {
    final currentAddress = _address;
    final currentShipping = _selectedShippingMethod;
    final currentPayment = _selectedPaymentMethod;

    if (currentAddress == null ||
        currentShipping == null ||
        currentPayment == null ||
        !currentPayment.isEnabled) {
      _errorMessage = 'Complete the checkout details before placing the order.';
      notifyListeners();
      return false;
    }

    _isPlacingOrder = true;
    _errorMessage = null;
    _completedOrderId = null;
    notifyListeners();

    try {
      final result = await repository.placeOrder(
        order: CheckoutOrderDraft(
          items: _items,
          address: currentAddress,
          shippingMethod: currentShipping,
          paymentMethod: currentPayment,
          totals: totals,
          promoCode: _promoCode?.code,
        ),
        userId: userId,
        accessToken: accessToken,
      );

      _completedOrderId = result.orderId;
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
