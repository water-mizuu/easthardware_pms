// ignore_for_file: use_key_in_widget_constructors

import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

class AutoAutoSuggestBox<T> extends StatefulWidget {
  /// Creates a fluent-styled auto suggest box.
  const AutoAutoSuggestBox({
    super.key,
    required this.items,
    this.controller,
    this.onChanged,
    this.onSelected,
    this.onOverlayVisibilityChanged,
    this.itemBuilder,
    this.noResultsFoundBuilder,
    this.sorter,
    this.leadingIcon,
    this.trailingIcon,
    this.clearButtonEnabled = true,
    this.placeholder,
    this.placeholderStyle,
    this.style,
    this.decoration,
    this.foregroundDecoration,
    this.highlightColor,
    this.unfocusedColor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2.0),
    this.cursorWidth = 1.5,
    this.showCursor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enableKeyboardControls = true,
    this.enabled = true,
    this.inputFormatters,
    this.maxPopupHeight = kAutoSuggestBoxPopupMaxHeight,
  })  : autovalidateMode = AutovalidateMode.disabled,
        validator = null;

  /// Creates a fluent-styled auto suggest form box.
  const AutoAutoSuggestBox.form({
    super.key,
    required this.items,
    this.controller,
    this.onChanged,
    this.onSelected,
    this.onOverlayVisibilityChanged,
    this.itemBuilder,
    this.noResultsFoundBuilder,
    this.sorter,
    this.leadingIcon,
    this.trailingIcon,
    this.clearButtonEnabled = true,
    this.placeholder,
    this.placeholderStyle,
    this.style,
    this.decoration,
    this.foregroundDecoration,
    this.highlightColor,
    this.unfocusedColor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2.0),
    this.cursorWidth = 1.5,
    this.showCursor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enableKeyboardControls = true,
    this.enabled = true,
    this.inputFormatters,
    this.maxPopupHeight = kAutoSuggestBoxPopupMaxHeight,
  });

  /// The list of items to display to the user to pick
  final List<AutoSuggestBoxItem<T>> items;

  /// The controller used to have control over what to show on the [TextBox].
  final TextEditingController? controller;

  /// Called when the text is updated
  final OnChangeAutoSuggestBox? onChanged;

  /// Called when the user selected a value.
  final ValueChanged<AutoSuggestBoxItem<T>>? onSelected;

  /// Called when the overlay visibility changes
  final ValueChanged<bool>? onOverlayVisibilityChanged;

  /// A callback function that builds the items in the overlay.
  ///
  /// Use [noResultsFoundBuilder] to build the overlay when no item is provided
  final AutoSuggestBoxItemBuilder? itemBuilder;

  /// Widget to be displayed when none of the items fit the [sorter]
  final WidgetBuilder? noResultsFoundBuilder;

  /// Sort the [items] based on the current query text
  ///
  /// See also:
  ///
  ///  * [AutoSuggestBox.defaultItemSorter], the default item sorter
  final AutoSuggestBoxSorter<T>? sorter;

  /// A widget displayed at the start of the text box
  ///
  /// Usually an [IconButton] or [Icon]
  final Widget? leadingIcon;

  /// A widget displayed at the end of the text box
  ///
  /// Usually an [IconButton] or [Icon]
  final Widget? trailingIcon;

  /// Whether the close button is enabled
  ///
  /// Defaults to true
  final bool clearButtonEnabled;

  /// The text shown when the text box is empty
  ///
  /// See also:
  ///
  ///  * [TextBox.placeholder]
  final String? placeholder;

  /// The style of [placeholder]
  ///
  /// See also:
  ///
  ///  * [TextBox.placeholderStyle]
  final TextStyle? placeholderStyle;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// Controls the [BoxDecoration] of the box behind the text input.
  final BoxDecoration? decoration;

  /// Controls the [BoxDecoration] of the box in front of the text input.
  ///
  /// If [highlightColor] is provided, this must not be provided
  final BoxDecoration? foregroundDecoration;

  /// The highlight color of the text box.
  ///
  /// If [foregroundDecoration] is provided, this must not be provided.
  ///
  /// See also:
  ///  * [unfocusedColor], displayed when the field is not focused
  final Color? highlightColor;

  /// The unfocused color of the highlight border.
  ///
  /// See also:
  ///   * [highlightColor], displayed when the field is focused
  final Color? unfocusedColor;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorHeight}
  final double? cursorHeight;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius cursorRadius;

  /// The color of the cursor.
  ///
  /// The cursor indicates the current location of text insertion point in
  /// the field.
  final Color? cursorColor;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool? showCursor;

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  final ui.BoxHeightStyle selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  final ui.BoxWidthStyle selectionWidthStyle;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [FluentThemeData.brightness].
  final Brightness? keyboardAppearance;

  /// {@macro flutter.widgets.editableText.scrollPadding}
  final EdgeInsets scrollPadding;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  final FormFieldValidator<String>? validator;

  /// Used to enable/disable this form field auto validation and update its
  /// error text.
  final AutovalidateMode autovalidateMode;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// An object that can be used by a stateful widget to obtain the keyboard focus
  /// and to handle keyboard events.
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// Whether the items can be selected using the keyboard
  ///
  /// Arrow Up - focus the item above
  /// Arrow Down - focus the item below
  /// Enter - select the current focused item
  /// Escape - close the suggestions overlay
  ///
  /// Defaults to `true`
  final bool enableKeyboardControls;

  /// Whether the text box is enabled
  ///
  /// See also:
  ///  * [TextBox.enabled]
  final bool enabled;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// The max height the popup can assume.
  ///
  /// The suggestion popup can assume the space available below the text box but,
  /// by default, it's limited to a 380px height. If the value provided is greater
  /// than the available space, the box is limited to the available space.
  final double maxPopupHeight;

  @override
  State<AutoAutoSuggestBox<T>> createState() => _AutoAutoSuggestBoxState<T>();
}

class _AutoAutoSuggestBoxState<T> extends State<AutoAutoSuggestBox<T>> {
  late final GlobalKey<AutoSuggestBoxState<T>> _key;
  late FocusNode _focusNode;
  late bool _isFocused;

  @override
  void initState() {
    super.initState();

    _key = GlobalKey();
    _focusNode = widget.focusNode ?? FocusNode()
      ..addListener(_focusNodeListen);
    _isFocused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(AutoAutoSuggestBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// If the user decides to add a focus node dynamically,
    ///   we need to update.
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _focusNode.removeListener(_focusNodeListen);
      _focusNode = widget.focusNode!..addListener(_focusNodeListen);
    } else if (oldWidget.focusNode != null && widget.focusNode == null) {
      _focusNode.removeListener(_focusNodeListen);
      _focusNode = FocusNode()..addListener(_focusNodeListen);
    }

    /// Else they are the same, and should not change.
  }

  void _focusNodeListen() {
    if (!_isFocused && _focusNode.hasFocus) {
      if (_key.currentState case final state?) {
        state.showOverlay();
      }
    }

    _isFocused = _focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    return AutoSuggestBox.form(
      key: _key,
      items: widget.items,
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSelected: widget.onSelected,
      onOverlayVisibilityChanged: widget.onOverlayVisibilityChanged,
      itemBuilder: widget.itemBuilder,
      noResultsFoundBuilder: widget.noResultsFoundBuilder,
      sorter: widget.sorter,
      leadingIcon: widget.leadingIcon,
      trailingIcon: widget.trailingIcon,
      clearButtonEnabled: widget.clearButtonEnabled,
      placeholder: widget.placeholder,
      placeholderStyle: widget.placeholderStyle,
      style: widget.style,
      decoration: widget.decoration,
      foregroundDecoration: widget.foregroundDecoration,
      highlightColor: widget.highlightColor,
      unfocusedColor: widget.unfocusedColor,
      cursorColor: widget.cursorColor,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorWidth: widget.cursorWidth,
      showCursor: widget.showCursor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enableKeyboardControls: widget.enableKeyboardControls,
      enabled: widget.enabled,
      inputFormatters: widget.inputFormatters,
      maxPopupHeight: widget.maxPopupHeight,
    );
  }
}
