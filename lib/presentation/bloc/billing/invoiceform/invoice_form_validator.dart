import 'package:fluent_ui/fluent_ui.dart';

mixin InvoiceFormValidator on Widget {
  String? validateInvoiceNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invoice number is required';
    }
    return null;
  }

  String? validateInvoiceDate(DateTime? value) {
    if (value == null) {
      return 'Invoice date is required';
    }
    return null;
  }

  String? validateDueDate(DateTime? value) {
    if (value == null) {
      return 'Due date is required';
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
