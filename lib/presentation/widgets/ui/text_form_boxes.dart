import 'package:easthardware_pms/presentation/widgets/ui/decorations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

class TextFormBoxes extends TextFormBox {
  TextFormBoxes(
      {super.decoration,
      super.key,
      super.controller,
      super.focusNode,
      super.autofillHints,
      super.placeholder,
      super.placeholderStyle,
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
      super.inputFormatters})
      : super();

  factory TextFormBoxes.ghost({
    List<TextInputFormatter>? inputFormatters,
    TextStyle? style,
    TextEditingController? controller,
    Function(String)? onChanged,
    String? placeholder,
    TextStyle? placeholderStyle,
    bool? enabled,
  }) {
    return TextFormBoxes(
      inputFormatters: inputFormatters,
      style: style,
      placeholderStyle: placeholderStyle,
      controller: controller,
      enabled: enabled ?? true,
      placeholder: placeholder,
      onChanged: onChanged,
      decoration: BoxDecorations.ghost,
      highlightColor: Colors.transparent,
      unfocusedColor: Colors.transparent,
      padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 5, 6),
    );
  }
}
