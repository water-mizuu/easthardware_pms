import 'package:fluent_ui/fluent_ui.dart';

class CompoundButton extends StatelessWidget {

  const CompoundButton({
    super.key,
    required this.onTextChanged,
    required this.onComboBoxSelected,
    required this.items,
    this.selected,
    required this.text,
  });
  final Function(dynamic value) onTextChanged;
  final Function(dynamic value) onComboBoxSelected;
  final List<ComboBoxItem> items;
  final String text;
  final dynamic selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextBox(
            controller: TextEditingController(text: text),
            onChanged: onTextChanged,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),
        ),
        Expanded(
          child: ComboBox(
            placeholder: const Text("Select"),
            isExpanded: true,
            onChanged: onComboBoxSelected,
            value: selected,
            items: items,
          ),
        ),
      ],
    );
  }
}
