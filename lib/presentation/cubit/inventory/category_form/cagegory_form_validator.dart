import 'package:fluent_ui/fluent_ui.dart';

mixin CagegoryFormValidator on Widget {
  String? validateName(String name, List<String> existingNames) {
    if (existingNames.contains(name)) {
      return 'Category already exist';
    }
    return null;
  }
}
