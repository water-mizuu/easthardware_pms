import 'package:fluent_ui/fluent_ui.dart';

class BoxDecorations {
  static const BoxDecoration ghost = BoxDecoration(
    border: Border(),
    color: Colors.transparent,
  );
  static BoxDecoration bad = BoxDecoration(
    color: Colors.errorSecondaryColor,
  );
}
