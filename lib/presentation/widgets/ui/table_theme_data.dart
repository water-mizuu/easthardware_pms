import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Theme, ThemeData, DataTableThemeData, CardTheme;

class TableThemeData extends StatelessWidget {
  const TableThemeData({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        dataTableTheme: const DataTableThemeData(
          columnSpacing: 0,
          dividerThickness: 0,
          headingRowHeight: 36.0,
          dataRowMinHeight: 42.0,
          dataRowMaxHeight: 48.0,
        ),
        cardTheme: CardTheme(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          color: Colors.white,
        ),
      ),
      child: child,
    );
  }
}
