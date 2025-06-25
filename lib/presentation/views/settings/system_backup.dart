import 'package:easthardware_pms/presentation/cubit/database_information/database_information_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/utils/number_string.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const HeadingText('System Backup');
  }
}

class _DatabaseAndBackupInformation extends StatelessWidget {
  const _DatabaseAndBackupInformation();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Database and Backup Information'),
        LayoutMode.builder((context, mode, keys) {
          switch (mode) {
            case LayoutMode.wide:
              return Row(
                children: const [
                  Expanded(child: _RecordCountInDatabase()),
                  Expanded(child: _RecordCountInDatabase()),
                  Expanded(child: _RecordCountInDatabase()),
                  Expanded(child: _RecordCountInDatabase()),
                ].withSpacing(() => Spacing.h8),
              );
            case LayoutMode.constrained:
              return Column(
                children: [
                  Row(
                    children: const [
                      Expanded(child: _RecordCountInDatabase()),
                      Expanded(child: _RecordCountInDatabase()),
                    ].withSpacing(() => Spacing.h8),
                  ),
                  Row(
                    children: const [
                      Expanded(child: _RecordCountInDatabase()),
                      Expanded(child: _RecordCountInDatabase()),
                    ].withSpacing(() => Spacing.h8),
                  ),
                ].withSpacing(() => Spacing.v8),
              );
            case LayoutMode.compact:
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _RecordCountInDatabase(),
                  _RecordCountInDatabase(),
                  _RecordCountInDatabase(),
                  _RecordCountInDatabase()
                ].withSpacing(() => Spacing.v8),
              );
          }
        }),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _RecordCountInDatabase extends StatelessWidget {
  const _RecordCountInDatabase();

  @override
  Widget build(BuildContext context) {
    final recordCount = context.watch<DatabaseInformationCubit>().state.recordCount;

    return KPICard(
      "Records in database",
      value: recordCount.toNumberString(),
      isExpanded: false,
    );
  }
}

class _DatabaseOptions extends StatelessWidget {
  const _DatabaseOptions();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _DatabaseBackups extends StatelessWidget {
  const _DatabaseBackups({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
