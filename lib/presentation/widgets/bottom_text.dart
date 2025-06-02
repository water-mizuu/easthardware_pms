import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';

/// This serves as a key to access the bottom text notifier from anywhere in the app.
///   This only wraps a [ValueNotifier<String>] to provide a simple way to access it.
class BottomTextNotifier {
  const BottomTextNotifier(this.notifier);
  final ValueNotifier<String> notifier;
}

class BottomText extends StatelessWidget {
  const BottomText({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final serverBloc = context.watch<ServerBloc>();
    final content = context.read<BottomTextNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              children: [
                const SizedBox(width: 2.0),
                const Icon(Icons.signal_cellular_alt_outlined),
                const SizedBox(width: 4.0),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: content.notifier,
                    builder: (context, value, child) {
                      return Text(value);
                    },
                  ),
                ),
                if (kDebugMode && serverBloc.state.databaseArgs != null)
                  Button(
                    child: const Text("Reset Connection"),
                    onPressed: () {
                      context.navigate(AppRoutes.login);
                      context.read<ServerBloc>().add(const ServerReset());
                    },
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
