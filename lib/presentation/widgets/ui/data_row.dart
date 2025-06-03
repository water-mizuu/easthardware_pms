import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow;

class DangerDataRow extends DataRow {
  DangerDataRow(
    List<DataCell> cells,
  ) : super(
          color: WidgetStatePropertyAll(Colors.red.lightest.withOpacity(0.6)),
          cells: cells,
        );
}

class WarningDataRow extends DataRow {
  WarningDataRow(
    List<DataCell> cells,
  ) : super(
          color: WidgetStatePropertyAll(Colors.orange.lightest.withOpacity(0.6)),
          cells: cells,
        );
}

class InfoDataRow extends DataRow {
  InfoDataRow(
    List<DataCell> cells,
  ) : super(
          color: WidgetStatePropertyAll(Colors.grey[30].withOpacity(0.6)),
          cells: cells,
        );
}

class SuccessDataRow extends DataRow {
  SuccessDataRow(
    List<DataCell> cells,
  ) : super(
          color: WidgetStatePropertyAll(Colors.green.lightest.withOpacity(0.6)),
          cells: cells,
        );
}
