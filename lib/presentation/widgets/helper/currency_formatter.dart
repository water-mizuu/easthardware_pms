import 'package:intl/intl.dart';

final class CurrencyFormatter {
  const CurrencyFormatter._();

  static String compact(double value) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    final formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      locale: 'en_PH',
      symbol: '₱',
    );

    return formatter.format(value);
  }

  static String full(double value) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    final formatter = NumberFormat.currency(
      decimalDigits: 2,
      locale: 'en_PH',
      symbol: '₱',
    );

    return formatter.format(value);
  }
}
