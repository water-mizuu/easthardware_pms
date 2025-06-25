import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluent_ui/src/controls/form/pickers/pickers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// The duration of a complete year
const kYearDuration = Duration(days: 365);

/// Returns the amount of months in the desired year
Iterable<int> _monthsInYear(
  DateTime localDate,
  DateTime startDate,
  DateTime endDate,
) sync* {
  if (localDate.year == startDate.year) {
    for (var current = startDate.month; current <= 12; current++) {
      yield current;
    }
  } else if (localDate.year == endDate.year) {
    for (var current = endDate.month; current <= 12; current++) {
      yield current;
    }
  } else {
    yield* List.generate(DateTime.monthsPerYear, (index) => index + 1);
  }
}

/// The fields used on date picker.
enum BorderedDatePickerField {
  /// The month field
  month,

  /// The day field
  day,

  /// The year field
  year,
}

/// The date picker gives you a standardized way to let users pick a localized
/// date value using touch, mouse, or keyboard input.
///
/// ![BorderedDatePicker Preview](https://docs.microsoft.com/en-us/windows/apps/design/controls/images/controls-datepicker-expand.gif)
///
/// See also:
///
///  * [TimePicker], which gives you a standardized way to let users pick a time
///    value
///  * <https://docs.microsoft.com/en-us/windows/apps/design/controls/date-picker>
class BorderedDatePicker extends StatelessWidget {
  /// Creates a date picker.
  BorderedDatePicker({
    super.key,
    required this.selected,
    this.onChanged,
    this.onCancel,
    this.header,
    this.headerStyle,
    this.showDay = true,
    this.showMonth = true,
    this.showYear = true,
    DateTime? startDate,
    DateTime? endDate,
    this.contentPadding = kPickerContentPadding,
    this.popupHeight = kPickerPopupHeight,
    this.focusNode,
    this.autofocus = false,
    this.locale,
    this.fieldOrder,
    this.fieldFlex,
  })  : startDate = startDate ?? DateTime.now().subtract(kYearDuration * 100),
        endDate = endDate ?? DateTime.now().add(kYearDuration * 25),
        assert(
          fieldFlex == null || fieldFlex.length == 3,
          'fieldFlex must be null or have a length of 3',
        );

  /// The current date selected date.
  ///
  /// If null, no date is going to be shown.
  final DateTime? selected;

  /// Whenever the current selected date is changed by the user.
  ///
  /// If null, the picker is considered disabled
  final ValueChanged<DateTime>? onChanged;

  /// Whenever the user cancels the date change.
  final VoidCallback? onCancel;

  /// The content of the header
  final String? header;

  /// The style of the [header]
  final TextStyle? headerStyle;

  /// Whenever to show the month field
  ///
  /// See also:
  ///
  ///  * [showDay], which configures whether to show the day field
  ///  * [showYear], which configures whether to show the year field
  final bool showMonth;

  /// Whenever to show the day field
  ///
  /// See also:
  ///
  ///  * [showMonth], which configures whether to show the month field
  ///  * [showYear], which configures whether to show the year field
  final bool showDay;

  /// Whenever to show the year field
  ///
  /// See also:
  ///
  ///  * [showDay], which configures whether to show the day field
  ///  * [showMonth], which configures whether to show the month field
  final bool showYear;

  /// The date displayed at the beggining
  ///
  /// Defaults to 100 to today
  final DateTime startDate;

  /// The date displayed at the end of the list
  ///
  /// Defaults to 25 years from today
  final DateTime endDate;

  /// The padding of the picker fields. Defaults to [kPickerContentPadding]
  final EdgeInsetsGeometry contentPadding;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The height of the popup.
  ///
  /// Defaults to [kPickerPopupHeight]
  final double popupHeight;

  /// The locale used to format the month name.
  ///
  /// If null, the system locale will be used.
  final Locale? locale;

  /// The order of the fields.
  ///
  /// If null, the order is based on the current locale.
  ///
  /// See also:
  ///
  ///  * [getDateOrderFromLocale], which returns the order of the fields based
  ///    on the current locale
  final List<DatePickerField>? fieldOrder;

  /// The flex of the fields.
  ///
  /// if null, the flex is base on the current locale.
  ///
  /// See also:
  ///
  /// * [getDateFlexFromLocale], which returns the flex of the fields based
  ///   on the current locale
  final List<int>? fieldFlex;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('selected', selected, ifNull: 'now'))
      ..add(FlagProperty(
        'showMonth',
        value: showMonth,
        ifFalse: 'not displaying month',
      ))
      ..add(FlagProperty(
        'showDay',
        value: showDay,
        ifFalse: 'not displaying day',
      ))
      ..add(FlagProperty(
        'showYear',
        value: showYear,
        ifFalse: 'not displaying year',
      ))
      ..add(DiagnosticsProperty<DateTime>('startDate', startDate))
      ..add(DiagnosticsProperty<DateTime>('endDate', endDate))
      ..add(DiagnosticsProperty('contentPadding', contentPadding))
      ..add(ObjectFlagProperty.has('focusNode', focusNode))
      ..add(FlagProperty(
        'autofocus',
        value: autofocus,
        ifFalse: 'manual focus',
      ))
      ..add(DoubleProperty(
        'popupHeight',
        popupHeight,
        defaultValue: kPickerPopupHeight,
      ))
      ..add(DiagnosticsProperty<Locale>('locale', locale))
      ..add(IterableProperty<DatePickerField>('fieldOrder', fieldOrder));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[100], width: 1.0),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: DatePicker(
        selected: selected,
        onChanged: onChanged,
        onCancel: onCancel,
        header: header,
        headerStyle: headerStyle,
        showMonth: showMonth,
        showDay: showDay,
        showYear: showYear,
        startDate: startDate,
        endDate: endDate,
        contentPadding: contentPadding,
        focusNode: focusNode,
        autofocus: autofocus,
        popupHeight: popupHeight,
        locale: locale,
        fieldOrder: fieldOrder,
        fieldFlex: fieldFlex,
      ),
    );
  }
}
