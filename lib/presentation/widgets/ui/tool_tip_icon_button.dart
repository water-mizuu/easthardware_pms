import 'package:fluent_ui/fluent_ui.dart';

class ToolTipIconButton extends StatelessWidget {
  const ToolTipIconButton(
      {super.key, required this.icon, required this.tooltip, required this.onPressed});
  final String tooltip;
  final Icon icon;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
        message: tooltip,
        useMousePosition: false,
        style: const TooltipThemeData(preferBelow: true),
        child: IconButton(
          icon: icon,
          onPressed: onPressed,
        ));
  }
}
