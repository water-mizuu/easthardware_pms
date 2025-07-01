import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/log_out_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

mixin NavigationPanelMixin {
  NavigationPaneItem navItem({
    IconData? icon,
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
      return _CustomPaneItem(
        icon: icon == null ? null : Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),

        /// A little hack to allow the [RouteIndexMapper] to access the route linked
        ///   to this item.
        infoBadge: route == null ? null : _hiddenRoute(route),
        body: const SizedBox.shrink(),
        onTap: onTap,
      );
    }
  }
}
mixin CommonSidePanelMixin on NavigationPanelMixin {
  Widget menuButton() {
    return Builder(builder: (context) {
      return switch (context.watch<PaneDisplayMode>()) {
        PaneDisplayMode.compact when !NavigationView.of(context).compactOverlayOpen => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
            child: Image.asset(
              'assets/icons/logo.png',
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

  List<NavigationPaneItem> footerItems(BuildContext context) {
    final user = context.watch<AuthenticationBloc>().state.user;
    return [
      if (kDebugMode) ...[
        navItem(
          icon: FluentIcons.device_bug,
          title: 'Clear database',
          color: Colors.red,
          onTap: () {
            context.read<ServerBloc>().add(const ServerDatabaseCleared());
          },
        ),
        navItem(
          icon: FluentIcons.insert_rows_below,
          title: 'Add mock items',
          color: Colors.green,
          onTap: () {
            context.read<ServerBloc>().add(const ServerMockDataAdded());
          },
        ),
      ],
      PaneItem(
        body: const NullWidget(),
        icon: const Icon(FluentIcons.contact),
        trailing: const Padding(
          padding: EdgeInsets.only(right: 6.0),
          child: Icon(FluentIcons.leave, size: 10.0),
        ),
        title: Text('${user!.firstName.toTitleCase()} ${user.lastName.toTitleCase()}'),
        onTap: () async {
          final userConfirmedLogout = await LogOutDialog.show();

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Builder(
        builder: (context) {
          final routes = context.select((ProvidedPaneItems p) => p.items);
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

class NullWidget extends StatelessWidget {
  const NullWidget({super.key});

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      "This widget should not be built. " //
      "It is a placeholder for null values.",
    );
  }
}

class _CustomPaneItem extends PaneItem {
  /// Creates a pane item.
  _CustomPaneItem({
    Widget? icon,
    required super.body,
    super.title,
    super.trailing,
    super.infoBadge,
    super.focusNode,
    super.autofocus = false,
    super.mouseCursor,
    super.tileColor,
    super.selectedTileColor,
    super.onTap,
    super.enabled = true,
  }) : super(icon: icon ?? const NullWidget());

  /// Used to construct the pane items all around [NavigationView]. You can
  /// customize how the pane items should look like by overriding this method
  @override
  Widget build(
    BuildContext context,
    bool selected,
    VoidCallback? onPressed, {
    PaneDisplayMode? displayMode,
    bool showTextOnTop = true,
    int? itemIndex,
    bool? autofocus,
  }) {
    final maybeBody = InheritedNavigationView.maybeOf(context);
    final mode = displayMode ??
        maybeBody?.displayMode ??
        maybeBody?.pane?.displayMode ??
        PaneDisplayMode.minimal;
    assert(mode != PaneDisplayMode.auto);
    assert(debugCheckHasFluentTheme(context));

    final isTransitioning = maybeBody?.isTransitioning ?? false;

    final theme = NavigationPaneTheme.of(context);
    final titleText = title?.getProperty<String>() ?? '';

    final baseStyle = title?.getProperty<TextStyle>() ?? const TextStyle();

    final isTop = mode == PaneDisplayMode.top;
    final isMinimal = mode == PaneDisplayMode.minimal;
    final isCompact = mode == PaneDisplayMode.compact;

    final onItemTapped = (onPressed == null && onTap == null) || !enabled || isTransitioning
        ? null
        : () {
            onPressed?.call();
            onTap?.call();
          };

    final button = HoverButton(
      autofocus: autofocus ?? this.autofocus,
      focusNode: focusNode,
      onPressed: onItemTapped,
      cursor: mouseCursor,
      focusEnabled: isMinimal ? (maybeBody?.minimalPaneOpen ?? false) : true,
      forceEnabled: enabled,
      builder: (context, states) {
        final textStyle = () {
          final style = !isTop
              ? (selected
                  ? theme.selectedTextStyle?.resolve(states)
                  : theme.unselectedTextStyle?.resolve(states))
              : (selected
                  ? theme.selectedTopTextStyle?.resolve(states)
                  : theme.unselectedTopTextStyle?.resolve(states));
          if (style == null) return baseStyle;
          return style.merge(baseStyle);
        }();

        final textResult = titleText.isNotEmpty
            ? Padding(
                padding: theme.labelPadding ?? EdgeInsets.zero,
                child: RichText(
                  text: title!.getProperty<InlineSpan>(textStyle)!,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  textAlign: title?.getProperty<TextAlign>() ?? TextAlign.start,
                  textHeightBehavior: title?.getProperty<TextHeightBehavior>(),
                  textWidthBasis: title?.getProperty<TextWidthBasis>() ?? TextWidthBasis.parent,
                ),
              )
            : const SizedBox.shrink();
        Widget result() {
          final iconThemeData = IconThemeData(
            color: textStyle.color ??
                (selected
                    ? theme.selectedIconColor?.resolve(states)
                    : theme.unselectedIconColor?.resolve(states)),
            size: textStyle.fontSize ?? 16.0,
          );
          switch (mode) {
            case PaneDisplayMode.compact:
              return Container(
                key: itemKey,
                constraints: const BoxConstraints(
                  minHeight: kPaneItemMinHeight,
                ),
                alignment: AlignmentDirectional.center,
                child: Padding(
                  padding: theme.iconPadding ?? EdgeInsets.zero,
                  child: IconTheme.merge(
                    data: iconThemeData,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: () {
                        if (infoBadge != null) {
                          return Stack(
                            alignment: AlignmentDirectional.center,
                            clipBehavior: Clip.none,
                            children: [
                              icon,
                              PositionedDirectional(
                                end: -8,
                                top: -8,
                                child: infoBadge!,
                              ),
                            ],
                          );
                        }
                        return icon;
                      }(),
                    ),
                  ),
                ),
              );
            case PaneDisplayMode.minimal:
            case PaneDisplayMode.open:
              final shouldShowTrailing = !isTransitioning;

              return ConstrainedBox(
                key: itemKey,
                constraints: const BoxConstraints(
                  minHeight: kPaneItemMinHeight,
                ),
                child: Row(children: [
                  Padding(
                    padding: theme.iconPadding ?? EdgeInsets.zero,
                    child: IconTheme.merge(
                      data: iconThemeData,
                      child: Center(child: icon),
                    ),
                  ),
                  Expanded(child: textResult),
                  if (shouldShowTrailing) ...[
                    if (infoBadge != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: infoBadge!,
                      ),
                    if (trailing != null)
                      IconTheme.merge(
                        data: const IconThemeData(size: 16.0),
                        child: trailing!,
                      ),
                  ],
                ]),
              );
            case PaneDisplayMode.top:
              final Widget result = Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (icon is! NullWidget)
                    Padding(
                      padding: theme.iconPadding ?? EdgeInsets.zero,
                      child: IconTheme.merge(
                        data: iconThemeData,
                        child: Center(child: icon),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: SizedBox.shrink(),
                    ),
                  if (showTextOnTop) Center(child: textResult),
                  if (trailing != null)
                    IconTheme.merge(
                      data: const IconThemeData(size: 16.0),
                      child: trailing!,
                    ),
                ],
              );
              if (infoBadge != null) {
                return Stack(key: itemKey, clipBehavior: Clip.none, children: [
                  result,
                  if (infoBadge != null)
                    PositionedDirectional(
                      end: -3,
                      top: 3,
                      child: infoBadge!,
                    ),
                ]);
              }
              return KeyedSubtree(key: itemKey, child: result);
            default:
              throw '$mode is not a supported type';
          }
        }

        return Semantics(
          label: titleText.isEmpty ? null : titleText,
          selected: selected,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: () {
                final tileColor =
                    this.tileColor ?? theme.tileColor ?? kDefaultPaneItemColor(context, isTop);
                final newStates = states.toSet()..remove(WidgetState.disabled);
                if (selected && selectedTileColor != null) {
                  return selectedTileColor!.resolve(newStates);
                }
                return tileColor.resolve(
                  selected
                      ? {
                          states.isHovered ? WidgetState.pressed : WidgetState.hovered,
                        }
                      : newStates,
                );
              }(),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: FocusBorder(
              focused: states.isFocused,
              renderOutside: false,
              child: () {
                final showTooltip = ((isTop && !showTextOnTop) || isCompact) &&
                    titleText.isNotEmpty &&
                    !states.isDisabled;

                if (showTooltip) {
                  return Tooltip(
                    richMessage: title?.getProperty<InlineSpan>(),
                    style: TooltipThemeData(textStyle: baseStyle),
                    child: result(),
                  );
                }

                return result();
              }(),
            ),
          ),
        );
      },
    );

    final index = () {
      if (itemIndex != null) return itemIndex;
      if (maybeBody?.pane?.indicator != null) {
        return maybeBody!.pane!.effectiveIndexOf(this);
      }
    }();

    return Padding(
      key: key,
      padding: const EdgeInsetsDirectional.only(bottom: 4.0),
      child: () {
        // If there is an indicator and the item is an effective item
        if (maybeBody?.pane?.indicator != null && index != null && !index.isNegative) {
          final key = PaneItemKeys.of(index, context);

          return Stack(children: [
            button,
            Positioned.fill(
              child: InheritedNavigationView.merge(
                currentItemIndex: index,
                currentItemSelected: selected,
                child: KeyedSubtree(
                  key: key,
                  child: maybeBody!.pane!.indicator!,
                ),
              ),
            ),
          ]);
        }

        return button;
      }(),
    );
  }

  @override
  _CustomPaneItem copyWith({
    Widget? title,
    Widget? icon,
    Widget? infoBadge,
    Widget? trailing,
    Widget? body,
    FocusNode? focusNode,
    bool? autofocus,
    MouseCursor? mouseCursor,
    WidgetStateProperty<Color?>? tileColor,
    WidgetStateProperty<Color?>? selectedTileColor,
    VoidCallback? onTap,
    bool? enabled,
  }) {
    return _CustomPaneItem(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      infoBadge: infoBadge ?? this.infoBadge,
      trailing: trailing ?? this.trailing,
      body: body ?? this.body,
      focusNode: focusNode ?? this.focusNode,
      autofocus: autofocus ?? this.autofocus,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      tileColor: tileColor ?? this.tileColor,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
      onTap: onTap ?? this.onTap,
      enabled: enabled ?? this.enabled,
    );
  }
}
