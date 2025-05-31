import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class LayoutModeProvider extends StatelessWidget {
  const LayoutModeProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.maxWidth.isFinite,
          "LayoutModeProvider requires finite width constraints. "
          "This is usually caused by using it inside a widget that does not impose "
          "finite width constraints, such as a ListView or a Column without a fixed height.",
        );

        final width = constraints.maxWidth;
        final layoutMode = width > 850
            ? LayoutMode.wide
            : width > 600
                ? LayoutMode.constrained
                : LayoutMode.compact;

        return Provider.value(
          value: layoutMode,
          child: child,
        );
      },
    );
  }
}

enum LayoutMode {
  wide,
  constrained,
  compact;

  static Widget builder({required Widget Function(BuildContext context, LayoutMode mode) builder}) {
    return Builder(builder: (context) {
      final layoutMode = context.watch<LayoutMode>();

      return builder(context, layoutMode);
    });
  }
}
