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
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Builder(
          builder: (context) {
            final mode = context.watch<PaneDisplayMode>();
            final navigationView = NavigationView.of(context);

            if (mode == PaneDisplayMode.compact && !navigationView.compactOverlayOpen) {
              return SizedBox(
                height: 32.0,
                width: 32.0,
                child: Button(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
                    shape: const WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  child: const Center(child: Icon(FluentIcons.search)),
                  onPressed: () {
                    if (!navigationView.compactOverlayOpen) {
                      navigationView.toggleCompactOpenMode();
                    }
                  },
                ),
              );
            } else {
              return AutoSuggestBox(
                placeholder: "Search",
                trailingIcon: const Padding(
                  padding: EdgeInsets.only(right: 9.0),
                  child: Icon(FluentIcons.search, size: 12),
                ),
                items: [
                  AutoSuggestBoxItem(
                    value: "Label",
                    label: "Search",
                    onSelected: () {
                      // Implement search functionality here
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
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

Widget _hiddenRoute(AppRoute route) => SizedBox(width: 0.0, height: 0.0, child: RouteText(route));

class RouteText extends Text {
  const RouteText(AppRoute data, {super.key}) : super(data as String, overflow: TextOverflow.clip);
}
