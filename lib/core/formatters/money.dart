/// Catalog totals are EGP; MyFatoorah's fixed 1 KWD test is separate.
class Money {
  Money._();

  static String format(num? value, {String currency = 'EGP'}) {
    final amount = (value ?? 0).toDouble();
    final text = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$text $currency';
  }
}
