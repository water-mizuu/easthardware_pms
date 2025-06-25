import 'package:fluent_ui/fluent_ui.dart';

class TextStyles {
  static TextStyle onSurfaceVariant = TextStyle(
    color: Colors.grey[120],
  );
  static TextStyle onSurface = TextStyle(
    color: Colors.grey[160],
  );
  static const TextStyle error = TextStyle(
    color: Colors.errorPrimaryColor,
  );
  static const TextStyle strong = TextStyle(
    fontWeight: FontWeight.w500,
  );
  static const TextStyle display = TextStyle(
    fontSize: 22,
  );
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle tooltip = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle tableHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle tableBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
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
