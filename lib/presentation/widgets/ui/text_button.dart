import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class TextButton extends StatelessWidget {
  const TextButton(
    this.text, {
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  final IconData? icon;
  final String text;
  final Function()? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: AppPadding.a4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final icon?) ...[Icon(icon, size: 12.0), Spacing.h8],
            ButtonText(text, color: color),
          ],
        ),
      ),
    );
  }
}

class TextButtonFilled extends StatelessWidget {
  const TextButtonFilled(
    this.text, {
    required this.onPressed,
    super.key,
  });

  final String text;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: AppPadding.a4,
        child: ButtonText(text),
      ),
    );
  }
}
