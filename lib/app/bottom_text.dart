import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';

class BottomTextNotifier {
  final ValueNotifier<String> notifier;

  const BottomTextNotifier(this.notifier);
}

class BottomText extends StatelessWidget {
  const BottomText({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final serverBloc = context.watch<ServerBloc>();
    var content = context.read<BottomTextNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.accessibility),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: content.notifier,
                      builder: (context, value, child) {
                        return Text(value);
                      },
                    ),
                  ),
                  if (serverBloc.state.databaseArgs != null)
                    Button(
                      child: const Text("Reset Connection"),
                      onPressed: () {
                        context.read<ServerBloc>().add(ServerReset());
                      },
                    ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
