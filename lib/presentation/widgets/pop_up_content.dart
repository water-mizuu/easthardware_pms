import 'package:fluent_ui/fluent_ui.dart';

class CustomDialog extends StatelessWidget {
  /// Creates a content dialog.
  const CustomDialog({
    super.key,
    required this.child,
    this.style,
    this.constraints = kDefaultContentDialogConstraints,
  });

  final Widget child;

  /// The style used by this dialog. If non-null, it's merged with
  /// [FluentThemeData.dialogTheme]
  final ContentDialogThemeData? style;

  /// The constraints of the dialog. It defaults to `BoxConstraints(maxWidth: 368)`
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final style = ContentDialogThemeData.standard(FluentTheme.of(
      context,
    )).merge(FluentTheme.of(context).dialogTheme.merge(this.style));

    return Align(
      alignment: AlignmentDirectional.center,
      child: Container(
        constraints: constraints,
        decoration: style.decoration,
        child: child,
      ),
    );
  }
}
