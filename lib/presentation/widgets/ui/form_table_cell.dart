import 'package:fluent_ui/fluent_ui.dart';

class FormTableCell extends Container {
  FormTableCell({
    super.key,
    super.child,
  }) : super(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(
                width: 0.5,
                color: Colors.transparent,
              ),
            ),
          ),
        );
}
