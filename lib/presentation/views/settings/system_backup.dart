import 'dart:async';

import 'package:easthardware_pms/presentation/cubit/database_information/database_information_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/number_string.dart';
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
          _DatabaseAndBackupInformation(),
          _DatabaseOptions(),
          _DatabaseBackups(),
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
      final card1 = _LastBackup(key: keys['1']);
      final card2 = _RecordCountInDatabase(key: keys['2']);
      final card3 = _RecordCountInDatabase(key: keys['3']);

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

class _LastBackup extends StatelessWidget {
  const _LastBackup({super.key});

  @override
  Widget build(BuildContext context) {
    final backups = context.watch<DatabaseInformationCubit>().state.allBackupPaths;
    final lastBackupDate = backups.isNotEmpty
        ? backups
            .map((b) => b.split("_").last)
            .map(path.basenameWithoutExtension)
            .map(int.parse)
            .map(DateTime.fromMillisecondsSinceEpoch)
            .reduce((a, b) => a.isAfter(b) ? a : b) // Get the most recent date
            .toLocal() // Convert to local time
        // Assuming the last backup path is a date string
        : null;

    return KPICard(
      "Last backup",
      value: lastBackupDate?.toString() ?? "Never",
      icon: const Icon(FluentIcons.clock),
      isExpanded: false,
    );
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
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Encryption Key', style: TextStyles.body),
                        Spacing.v4,
                        TextBox(
                          controller: textController,
                          placeholder: 'Enter an encryption key',
                          autofocus: true,
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
      _backupPaths = backupPaths.toList()..sort((a, b) => a.compareTo(b));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final backup in _backupPaths)
          Row(
            key: ValueKey(backup),
            children: [
              Text(backup),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(FluentIcons.update_restore),
                    onPressed: () {
                      final textController = TextEditingController();

                      unawaited(showDialog(
                        context: context,
                        builder: (context) {
                          return ContentDialog(
                            title: const Text('Restore backup'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Encryption Key', style: TextStyles.body),
                                Spacing.v4,
                                TextBox(
                                  controller: textController,
                                  placeholder: 'Enter an encryption key',
                                  autofocus: true,
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
                                onPressed: () {
                                  final key = textController.text.trim();
                                  if (key.isEmpty) return;

                                  context
                                    ..read<DatabaseInformationCubit>()
                                        .restoreBackup(path: backup, key: key)
                                    ..pop();
                                },
                              ),
                            ],
                          );
                        },
                      ));
                    },
                  ),
                  Spacing.h8,
                  IconButton(
                    icon: const Icon(FluentIcons.delete),
                    onPressed: () {
                      setState(() {
                        _backupPaths.remove(backup);
                      });
                    },
                  ),
                ],
              )
            ],
          ),
      ],
    );
  }
}
