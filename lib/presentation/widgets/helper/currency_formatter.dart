import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:intl/intl.dart';

final class CurrencyFormatter {
  const CurrencyFormatter._();

  static String compact(double value, [String symbol = DEFAULT_CURRENCY_SYMBOL]) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    final formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      locale: DEFAULT_LOCALE,
      symbol: symbol,
    );

    return formatter.format(value == 0.0 ? value.abs() : value);
  }

  static String full(double value, [String symbol = DEFAULT_CURRENCY_SYMBOL]) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    final formatter = NumberFormat.currency(
      decimalDigits: 2,
      locale: DEFAULT_LOCALE,
      symbol: symbol,
    );

    return formatter.format(value == 0.0 ? value.abs() : value);
  }
}
