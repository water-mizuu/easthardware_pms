import 'package:easthardware_pms/presentation/widgets/ui/box_decorations.dart';
import 'package:fluent_ui/fluent_ui.dart';

class TextFormBoxes extends TextFormBox {
  TextFormBoxes({
    super.decoration,
    super.key,
    super.controller,
    super.focusNode,
    super.autofillHints,
    super.placeholder,
    super.placeholderStyle = const TextStyle(color: Color(0xFFB0B0B0)),
    super.style,
    super.textAlign,
    super.textInputAction,
    super.keyboardType,
    super.textCapitalization,
    super.maxLines,
    super.minLines,
    super.onChanged,
    super.onEditingComplete,
    super.onFieldSubmitted,
    super.onTapOutside,
    super.onSaved,
    super.validator,
    super.enabled,
    super.readOnly,
    super.highlightColor,
    super.unfocusedColor,
    super.padding,
  }) : super();

  factory TextFormBoxes.ghost({
    TextEditingController? controller,
    Function(String)? onChanged,
    String? placeholder,
    bool? enabled,
  }) {
    return TextFormBoxes(
      controller: controller,
      enabled: enabled ?? true,
      placeholder: placeholder,
      onChanged: onChanged,
      decoration: BoxDecorations.ghost,
      highlightColor: Colors.transparent,
      unfocusedColor: Colors.transparent,
      padding: const EdgeInsetsDirectional.fromSTEB(0, 5, 0, 6),
    );
  }
}
