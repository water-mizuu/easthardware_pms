import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

enum LayoutMode {
  wide,
  constrained,
  compact;

  static Widget provider({
    required Widget child,
  }) {
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

  // ignore: library_private_types_in_public_api
  static Widget builder(_LayoutModeBuilder builder) {
    return InheritedProvider(
      create: (_) => GlobalKeyGenerator(),
      dispose: (_, value) => value.dispose(),
      child: Builder(builder: (context) {
        final layoutMode = context.watch<LayoutMode>();

        return builder(context, layoutMode, context.read<GlobalKeyGenerator>());
      }),
    );
  }
}

typedef _LayoutModeBuilder = Widget Function(
  BuildContext context,
  LayoutMode mode,
  GlobalKeyGenerator keys,
);

class GlobalKeyGenerator {
  GlobalKeyGenerator() : _keys = {};
  late final Map<String, GlobalKey> _keys;

  GlobalKey operator [](String name) {
    if (!_keys.containsKey(name)) {
      _keys[name] = GlobalKey();
    }
    return _keys[name]!;
  }

  void dispose() {
    _keys.clear();
  }
}
