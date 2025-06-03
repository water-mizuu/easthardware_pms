import 'package:fluent_ui/fluent_ui.dart';

class Badge extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color? color;
  final double? padding;
  final double? fontSize;

  const Badge({
    super.key,
    required this.child,
    this.label,
    this.color,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (label != null)
          Positioned(
            right: padding ?? 8.0,
            top: padding ?? 8.0,
            child: Container(
              padding: EdgeInsets.all(padding ?? 4.0),
              decoration: BoxDecoration(
                color: color ?? Colors.blue.dark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: fontSize ?? 12.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
