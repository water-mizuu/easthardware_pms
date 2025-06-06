import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/log_out_dialog.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

mixin CommonSidePanelMixin {
  Widget menuButton() {
    return Builder(builder: (context) {
      return switch (context.watch<PaneDisplayMode>()) {
        PaneDisplayMode.compact when !NavigationView.of(context).compactOverlayOpen => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
            child: Image.asset(
              'assets/icons/app.png',
              height: 18,
              width: 18,
            ),
          ),
        _ => const SizedBox.shrink(),
      };
    });
  }

  PaneItemWidgetAdapter navSearch() {
    return PaneItemWidgetAdapter(
      applyPadding: false,
      child: const _SearchPaneItem(),
    );
  }

  NavigationPaneItem navItem({
    required IconData icon,
    required String title,
    Color? color,
    AppRoute<Null>? route,
    List<NavigationPaneItem>? items,
    VoidCallback? onTap,
  }) {
    if (items != null && items.isNotEmpty) {
      return PaneItemExpander(
        icon: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        items: items,

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: route == null ? null : _hiddenRoute(route),
        body: const SizedBox.shrink(),
      );
    } else {
      return PaneItem(
        icon: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: route == null ? null : _hiddenRoute(route),
        body: const SizedBox.shrink(),
        onTap: onTap,
      );
    }
  }

  List<NavigationPaneItem> footerItems(BuildContext context) {
    return [
      navItem(
        icon: FluentIcons.leave,
        title: 'Log Out',
        color: Colors.red,
        onTap: () async {
          final userConfirmedLogout = await LogOutDialog.show(context);
          if (!context.mounted) return;
          if (userConfirmedLogout) {
            context.read<AuthenticationBloc>().add(const AuthenticationLogoutEvent());
          }
        },
      ),
    ];
  }
}

class _SearchPaneItem extends StatefulWidget {
  const _SearchPaneItem();

  @override
  State<_SearchPaneItem> createState() => _SearchPaneItemState();
}

class _SearchPaneItemState extends State<_SearchPaneItem> {
  late final FocusNode searchBoxFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final routes = context.read<ProvidedPaneItems>().items;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Builder(
        builder: (context) {
          final mode = context.watch<PaneDisplayMode>();
          final navigationView = NavigationView.of(context);

          if (mode == PaneDisplayMode.compact && !navigationView.compactOverlayOpen) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 42.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: HoverButton(
                  onPressed: () {
                    if (!navigationView.compactOverlayOpen) {
                      navigationView.toggleCompactOpenMode();
                    }
                  },
                  builder: (context, states) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: () {
                          final tileColor = kDefaultPaneItemColor(context, false);
                          final newStates = states.toSet()..remove(WidgetState.disabled);

                          return tileColor.resolve(newStates);
                        }(),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(FluentIcons.search, size: 12.0),
                    );
                  },
                ),
              ),
            );
          } else {
            return Builder(
              builder: (context) {
                final navigationView = NavigationView.of(context);
                if (navigationView.compactOverlayOpen) {
                  searchBoxFocusNode.requestFocus();
                } else {
                  searchBoxFocusNode.unfocus();
                }

                return AutoSuggestBox(
                  focusNode: searchBoxFocusNode,
                  placeholder: "Search",
                  trailingIcon: const Padding(
                    padding: EdgeInsets.only(right: 9.0),
                    child: Icon(FluentIcons.search, size: 12),
                  ),
                  items: [
                    for (final route in routes)
                      if (route
                          case PaneItem(
                            title: Text(data: final String title),
                            infoBadge: SizedBox(child: RouteText(:final AppRoute<Null> data))
                          ))
                        AutoSuggestBoxItem(
                          value: data,
                          label: title,
                          onSelected: () {
                            if (!context.mounted) return;

                            context.navigate(data);

                            if (NavigationView.of(context).compactOverlayOpen) {
                              NavigationView.of(context).toggleCompactOpenMode();
                            }
                          },
                        ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}

Widget _hiddenRoute(AppRoute route) => SizedBox(width: 0.0, height: 0.0, child: RouteText(route));

class RouteText extends Text {
  const RouteText(AppRoute data, {super.key}) : super(data as String, overflow: TextOverflow.clip);
}

extension ExpandPaneItemExtension on Iterable<NavigationPaneItem> {
  /// Flattens the list of NavigationPaneItems, expanding any PaneItemExpander items.
  Iterable<PaneItem> expandItems() {
    return expand(
      (item) => item is PaneItemExpander //
          ? [item, ...item.items.expandItems()]
          : item is PaneItem
              ? [item]
              : [],
    );
  }
}

class ProvidedPaneItems {
  const ProvidedPaneItems(this.items);

  final List<PaneItem> items;
}
