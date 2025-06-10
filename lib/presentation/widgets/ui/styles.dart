import 'package:fluent_ui/fluent_ui.dart';

class TextStyles {
  static const TextStyle inactive = TextStyle(
    color: Color(0xFFB0B0B0),
  );
  static const TextStyle active = TextStyle(
    color: Color(0xFF030303),
  );
  static const TextStyle error = TextStyle(
    color: Colors.errorPrimaryColor,
  );
}

class ButtonStyles {
  static ButtonStyle ghost = const ButtonStyle(
    padding: WidgetStatePropertyAll(
      EdgeInsetsDirectional.fromSTEB(0, 5, 0, 6),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent),
      ),
    ),
  );
  // Filled
  static ButtonStyle filled = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.blue.dark),
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(color: Colors.white),
    ),
  );
  // Outlined
  static ButtonStyle outlined = const ButtonStyle();
}
