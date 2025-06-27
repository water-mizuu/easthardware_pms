import 'dart:async';

import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Dialog shown when connection is lost and attempting to reconnect
class ConnectionLostDialog extends StatefulWidget {
  const ConnectionLostDialog({
    super.key,
    required this.onRetryNow,
    required this.onCancel,
    required this.reconnectAttempts,
    required this.maxReconnectAttempts,
    required this.nextReconnectTime,
  });

  final VoidCallback onRetryNow;
  final VoidCallback onCancel;
  final int reconnectAttempts;
  final int maxReconnectAttempts;
  final DateTime nextReconnectTime;

  static Future<void> show({
    required VoidCallback onRetryNow,
    required VoidCallback onCancel,
    required int reconnectAttempts,
    required int maxReconnectAttempts,
    required DateTime nextReconnectTime,
  }) async {
    return await showSingleDialog(
      (context) => ConnectionLostDialog(
        onRetryNow: onRetryNow,
        onCancel: onCancel,
        reconnectAttempts: reconnectAttempts,
        maxReconnectAttempts: maxReconnectAttempts,
        nextReconnectTime: nextReconnectTime,
      ),
    );
  }

  @override
  State<ConnectionLostDialog> createState() => _ConnectionLostDialogState();
}

class _ConnectionLostDialogState extends State<ConnectionLostDialog> {
  late Timer _timer;
  int _secondsUntilRetry = 0;

  @override
  void initState() {
    super.initState();
    _updateSecondsUntilRetry();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSecondsUntilRetry();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateSecondsUntilRetry() {
    final now = DateTime.now();
    final seconds = widget.nextReconnectTime.difference(now).inSeconds;
    setState(() {
      _secondsUntilRetry = seconds > 0 ? seconds : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLastAttempt = widget.reconnectAttempts >= widget.maxReconnectAttempts;

    return ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.plug_disconnected, color: Colors.red),
          Spacing.h8,
          const Text("Connection Lost"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "The connection to the server has been lost.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Spacing.v8,
          if (isLastAttempt)
            Text(
              "Maximum reconnection attempts reached. Please check your connection and try again.",
              style: TextStyle(color: Colors.red),
            )
          else ...[
            Text(
              "Attempt ${widget.reconnectAttempts} of ${widget.maxReconnectAttempts}",
            ),
            Spacing.v8,
            if (_secondsUntilRetry > 0)
              Text(
                "Next automatic retry in $_secondsUntilRetry seconds...",
                style: TextStyle(color: Colors.grey[100]),
              )
            else
              Text(
                "Attempting to reconnect...",
                style: TextStyle(color: Colors.blue),
              ),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: widget.onCancel,
          child: const Text("Cancel"),
        ),
        if (!isLastAttempt)
          FilledButton(
            onPressed: widget.onRetryNow,
            child: const Text("Retry Now"),
          ),
      ],
    );
  }
}
