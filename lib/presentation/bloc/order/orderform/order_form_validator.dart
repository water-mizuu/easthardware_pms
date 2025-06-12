import 'package:fluent_ui/fluent_ui.dart';

mixin OrderFormValidator on Widget {
  String? validatePayeeName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Payee name is required';
    }
    return null;
  }

  String? validateOrderDate(DateTime? value) {
    if (value == null) {
      return 'Order date is required';
    }
    if (value.isAfter(DateTime.now())) {
      return 'Order date cannot be in the future';
    }
    return null;
  }

  String? validatePaymentDate(DateTime? value, DateTime? orderDate) {
    if (value == null) {
      return 'Payment date is required';
    }
    if (orderDate != null && value.isBefore(orderDate)) {
      return 'Payment date cannot be before order date';
    }
    return null;
  }

  String? validateReferenceNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Reference number is required';
    }
    return null;
  }

  String? validateTotalAmount(double? value) {
    if (value == null || value <= 0) {
      return 'Total amount must be greater than zero';
    }
    return null;
  }
}
