import 'package:fluent_ui/fluent_ui.dart';

class TextStyles {
  static TextStyle inactive = TextStyle(
    color: Colors.grey[120],
  );
  static TextStyle active = TextStyle(
    color: Colors.grey[220],
  );
  static const TextStyle error = TextStyle(
    color: Colors.errorPrimaryColor,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle tableHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
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
