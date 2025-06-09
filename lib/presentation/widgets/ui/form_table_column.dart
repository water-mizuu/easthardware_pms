import 'package:fluent_ui/fluent_ui.dart';

class FormTableColumn extends Container {
  FormTableColumn({
    super.key,
    super.child,
  }) : super(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                width: 0.5,
                color: Colors.grey[60],
              ),
            ),
          ),
        );
}
