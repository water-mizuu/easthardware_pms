import 'package:fluent_ui/fluent_ui.dart';

extension WrapIfExtension on Widget {
  Widget wrapIf(bool condition, Widget Function(Widget) builder) {
    return condition ? builder(this) : this;
  }
}
