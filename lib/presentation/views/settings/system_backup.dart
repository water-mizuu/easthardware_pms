import 'dart:async';

import 'package:easthardware_pms/presentation/cubit/'
    'database_information/database_information_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/backup_delete_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/number_string.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

class SystemBackupPage extends StatelessWidget {
  const SystemBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _PageHeader(),
          Expanded(
            child: AnimatedSingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DatabaseAndBackupInformation(),
                  _DatabaseOptions(),
                  _DatabaseBackups(),
                ],
              ),
            ),
          ),
        ].withSpacing(() => Spacing.v8),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeadingText('System Backup'),
        GrayText('Database and Backup Information'),
      ],
    );
  }
}

class _DatabaseAndBackupInformation extends StatelessWidget {
  const _DatabaseAndBackupInformation();

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, mode, keys) {
      final card0 = _RecordCountInDatabase(key: keys['0']);
      final card1 = _LatestBackup(key: keys['1']);
      final card2 = _BackupCount(key: keys['2']);
      final card3 = _DatabaseSize(key: keys['3']);

      return switch (mode) {
        LayoutMode.wide => Row(
            children: [
              Expanded(child: card0),
              Expanded(child: card1),
              Expanded(child: card2),
              Expanded(child: card3),
            ].withSpacing(() => Spacing.h8),
          ),
        LayoutMode.constrained => Column(
            children: [
              Row(
                children: [
                  Expanded(child: card0),
                  Expanded(child: card1),
                ].withSpacing(() => Spacing.h8),
              ),
              Row(
                children: [
                  Expanded(child: card2),
                  Expanded(child: card3),
                ].withSpacing(() => Spacing.h8),
              ),
            ].withSpacing(() => Spacing.v8),
          ),
        LayoutMode.compact => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              card0,
              card1,
              card2,
              card3,
            ].withSpacing(() => Spacing.v8),
          ),
      };
    });
  }
}

class _RecordCountInDatabase extends StatelessWidget {
  const _RecordCountInDatabase({super.key});

  @override
  Widget build(BuildContext context) {
    final recordCount = context.watch<DatabaseInformationCubit>().state.recordCount;

    return KPICard(
      "Records in database",
      value: recordCount.toNumberString(),
      icon: const Icon(FluentIcons.database),
      isExpanded: false,
    );
  }
}

class _BackupCount extends StatelessWidget {
  const _BackupCount({super.key});

  @override
  Widget build(BuildContext context) {
    final backupCount = context.watch<DatabaseInformationCubit>().state.allBackupPaths.length;

    return KPICard(
      "Existing backups",
      value: backupCount.toNumberString(),
      icon: const Icon(FluentIcons.fax),
      isExpanded: false,
    );
  }
}

class _DatabaseSize extends StatelessWidget {
  const _DatabaseSize({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseSize = context.watch<DatabaseInformationCubit>().state.databaseSize;

    return KPICard(
      "Database size",
      value: databaseSize.toFileSizeString(), // You'd need to implement this extension
      icon: const Icon(FluentIcons.hard_drive),
      isExpanded: false,
    );
  }
}

class _LatestBackup extends StatelessWidget {
  const _LatestBackup({super.key});

  @override
  Widget build(BuildContext context) {
    final latestBackupDate = context.watch<DatabaseInformationCubit>().state.latestBackupDateTime;

    return TimerWidget(
      builder: (context, now) {
        /// Get duration since last backup.
        final durationSinceLastBackup = latestBackupDate != null //
            ? now.difference(latestBackupDate)
            : null;

        /// Convert duration to a human-readable string.
        final lastBackupDurationString = durationSinceLastBackup?.toAgo() ?? 'Never';

        return KPICard(
          "Latest backup",
          value: lastBackupDurationString,
          icon: const Icon(FluentIcons.clock),
          isExpanded: false,
        );
      },
    );
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({
    this.interval = const Duration(milliseconds: 500),
    required this.builder,
    super.key,
  });

  final Duration interval;
  final Widget Function(BuildContext context, DateTime time) builder;

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(widget.interval, (_) => _onTimerTick());
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _timer = Timer.periodic(widget.interval, (_) => _onTimerTick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, DateTime.now());
  }

  void _onTimerTick() {
    if (mounted) {
      setState(() {}); // Trigger a rebuild every second
    }
  }
}

class _DatabaseOptions extends StatelessWidget {
  const _DatabaseOptions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.cardPadding,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButtonFilled(
            'Create Backup',
            onPressed: () {
              final textController = TextEditingController();

              unawaited(showDialog(
                context: context,
                builder: (context) {
                  return ContentDialog(
                    title: const Text('Create backup'),
                    content: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SubheadingText('Encryption Key'),
                          TextBox(
                            controller: textController,
                            placeholder: 'Enter an encryption key',
                            autofocus: true,
                          ),
                          const RedText(
                            'The encryption key is used to encrypt the backup file. '
                            'Please remember this key, as will be required '
                            'to restore the backup.',
                          ),
                        ].withSpacing(() => Spacing.v8),
                      ),
                    ),
                    actions: [
                      Button(
                        child: const Text('Cancel'),
                        onPressed: () {
                          context.pop();
                        },
                      ),
                      FilledButton(
                        child: const Text('Ok'),
                        onPressed: () {
                          final key = textController.text.trim();
                          if (key.isEmpty) return;

                          context
                            ..read<DatabaseInformationCubit>().createBackup(key: key)
                            ..pop();
                        },
                      ),
                    ],
                  );
                },
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _DatabaseBackups extends StatefulWidget {
  const _DatabaseBackups();

  @override
  State<_DatabaseBackups> createState() => _DatabaseBackupsState();
}

class _DatabaseBackupsState extends State<_DatabaseBackups> {
  late List<String> _backupPaths;

  @override
  void initState() {
    super.initState();

    _backupPaths = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final backupPaths = context.watch<DatabaseInformationCubit>().state.allBackupPaths;
    if (backupPaths != _backupPaths) {
      _backupPaths = backupPaths.toList()..sort((a, b) => -a.compareTo(b));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacing.v12,
        const DisplayText('Created Backups'),
        Spacing.v4,
        for (final backup in _backupPaths) _BackupRow(key: ValueKey(backup), backup: backup),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.backup,
    super.key,
  });

  final String backup;

  @override
  Widget build(BuildContext context) {
    final (dateCreated, fileName) = _readFileName(backup);

    return Container(
      padding: AppPadding.cardPadding,
      decoration: BoxDecoration(color: FluentTheme.of(context).cardColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TimerWidget(builder: (context, now) {
            final formattedDate = _formatDate(dateCreated, now);

            return Text('Backup created on $formattedDate');
          }),
          Row(
            children: [
              TextButton(
                'Restore',
                onPressed: _onRestorePressed,
              ),
              Spacing.h8,
              TextButton(
                'Delete',
                color: Colors.red,
                onPressed: () => unawaited(_onDeletePressed(context)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _onRestorePressed() async {
    final errorNotifier = ValueNotifier<String?>(null);
    final textController = TextEditingController();
    try {
      await showSingleDialog((context) {
        return ContentDialog(
          title: const Text('Restore backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Encryption Key', style: TextStyles.body),
              Spacing.v4,
              ListenableBuilder(
                listenable: errorNotifier,
                builder: (context, _) {
                  return TextFormBox(
                    controller: textController,
                    placeholder: 'Enter an encryption key',
                    autofocus: true,
                    autovalidateMode: AutovalidateMode.always,
                    validator: (value) => errorNotifier.value,
                    onChanged: (value) {
                      errorNotifier.value = null; // Clear error on input change
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text('Cancel'),
              onPressed: () {
                context.pop();
              },
            ),
            FilledButton(
              child: const Text('Ok'),
              onPressed: () async {
                final key = textController.text.trim();
                if (key.isEmpty) return;

                final didSucceed = await context //
                    .read<DatabaseInformationCubit>()
                    .restoreBackup(path: backup, key: key);

                if (!context.mounted) return;
                if (didSucceed) {
                  final (dateCreated, _) = _readFileName(backup);
                  showNotification.success(
                    title: 'Backup restored',
                    message: 'Backup restored successfully to $dateCreated',
                  );

                  context.pop();
                } else {
                  errorNotifier.value =
                      'Failed to restore backup. Please check the key and try again.';
                }
              },
            ),
          ],
        );
      });
    } finally {
      errorNotifier.dispose();
      textController.dispose();
    }
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    /// Prompt the user for confirmation before deleting the backup.
    await BackupDeleteDialog.show(
      onSuccess: () async {
        /// Delete the backup.
        if (!context.mounted) return;

        /// Call the cubit to delete the backup.
        await context.read<DatabaseInformationCubit>().deleteBackup(path: backup);
      },
      onCancel: () {},
    );
  }

  static (DateTime, String) _readFileName(String backup) {
    final fileName = path.basenameWithoutExtension(backup);
    final intPart = fileName.split('_').last;
    final datePart = int.parse(intPart);
    final date = DateTime.fromMillisecondsSinceEpoch(datePart);

    return (date, fileName);
  }

  static String _formatDate(DateTime date, DateTime now) {
    final difference = now.difference(date);
    final dateString = date.toLocal().toIso8601String().split("T").first;

    if (difference.inDays > 0) {
      return '$dateString (${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago)';
    } else if (difference.inHours > 0) {
      return '$dateString (${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago)';
    } else if (difference.inMinutes > 0) {
      return '$dateString (${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago)';
    } else {
      return '$dateString (Just now)';
    }
  }
}

extension on Duration {
  String toAgo() {
    if (inDays > 0) {
      return '$inDays days ago';
    } else if (inHours > 0) {
      return '$inHours hours ago';
    } else if (inMinutes > 0) {
      return '$inMinutes minutes ago';
    } else {
      return 'Just now';
    }
  }
}
