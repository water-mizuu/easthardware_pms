import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/data_table_place_holder.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

class UserLogsPage extends StatelessWidget {
  const UserLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(),
          Expanded(
            child: AnimatedSingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  PageActions(),
                  UserLogDataTable(),
                ].withSpacing(() => Spacing.v16),
              ),
            ),
          ),
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () {
            context.navigate(AppRoutes.admin.users);
          },
        ),
        const DisplayText('User Logs'),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Search: ')),
                  Spacing.h8,
                  SizedBox(
                    width: 480,
                    child: TextBox(
                      placeholder: 'Search',
                      onChanged: (value) {
                        context.read<UserLogListBloc>().add(SearchQueryUpdatedEvent(value));
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Filter: ')),
                  Spacing.h8,
                  Selector(
                    selector: (_, UserLogListBloc bloc) => bloc.state.queryData.accessLevel,
                    builder: (context, accessLevel, _) {
                      return ComboBox<AccessLevel?>(
                        value: context.select((UserLogListBloc b) {
                          return b.state.queryData.accessLevel;
                        }),
                        onChanged: (value) {
                          context.read<UserLogListBloc>().add(AccessLevelQueryUpdatedEvent(value));
                        },
                        placeholder: const Text('Level of Access'),
                        items: [
                          const ComboBoxItem(value: null, child: Text('All')),
                          for (final accessLevel in AccessLevel.values)
                            ComboBoxItem(value: accessLevel, child: Text(accessLevel.toString())),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('From Date: ')),
                  Spacing.h8,
                  Selector(
                    selector: (_, UserLogListBloc b) => b.state.queryData.startDate,
                    builder: (context, startDate, _) {
                      return BorderedDatePicker(
                        selected: startDate,
                        onChanged: (value) {
                          context.read<UserLogListBloc>().add(StartDateQueryUpdatedEvent(value));
                        },
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('To Date: ')),
                  Spacing.h8,
                  Selector(
                    selector: (_, UserLogListBloc bloc) => bloc.state.queryData.endDate,
                    builder: (context, endDate, _) {
                      return BorderedDatePicker(
                        selected: endDate,
                        onChanged: (value) {
                          context.read<UserLogListBloc>().add(EndDateQueryUpdatedEvent(value));
                        },
                      );
                    },
                  ),
                ],
              ),
            ].withSpacing(() => Spacing.v4),
          ),
        ),
        TextButtonFilled(
          'Print Report',
          onPressed: () {
            showPdfOverlay(builder: (context, overlay) {
              return PdfOverlay(
                overlayEntry: overlay,
                generatorCreator: () => _UserLogsReportPdfGenerator(
                  logs: context.read<UserLogListBloc>().state.filteredLogs,
                  users: context.read<UserListBloc>().state.users,
                  startDate: context.read<UserLogListBloc>().state.queryData.startDate,
                  endDate: context.read<UserLogListBloc>().state.queryData.endDate,
                ),
              );
            });
          },
        ),
      ],
    );
  }
}

class UserLogDataTable extends StatelessWidget {
  const UserLogDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    final allUsers = context.watch<UserListBloc>().state.users;
    final memo = <int, User?>{};

    /// Finds a user by their ID, memoizing the result for performance.
    /// If the user is not found in the memo, it searches through all users.
    User? findUserById(int id) {
      if (!memo.containsKey(id)) {
        memo[id] = allUsers.where((user) => user.id == id).firstOrNull;
      }
      return memo[id]!;
    }

    final state = context.watch<UserLogListBloc>().state;
    switch (state.status) {
      case DataStatus.loading:
        return const SizedBox(
          height: 400,
          child: Center(
            child: ProgressRing(),
          ),
        );
      default:
        final filteredLogs = state.filteredLogs;

        if (filteredLogs.isEmpty) {
          return const DataTablePlaceHolder(FluentIcons.activity_feed, 'Logs');
        }
        return DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Action')),
            ],
            rows: [
              for (final log in filteredLogs)
                if (findUserById(log.userId) case final user?)
                  DataRowMapper.mapUserLogToRow(log, user),
            ],
          ),
        );
    }
  }
}

final class _UserLogsReportPdfGenerator implements PdfGenerator {
  const _UserLogsReportPdfGenerator({
    required this.logs,
    required this.users,
    required this.startDate,
    required this.endDate,
  });

  final List<UserLog> logs;
  final List<User> users;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName => 'User_Logs_Report_${startDate.toIso8601String().split('T').first}'
      '_to_${endDate.toIso8601String().split('T').first}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/app.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(context, logo),
        build: (context) => [_buildContent()],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Context context, ByteData logo) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Image(
                      pw.MemoryImage(logo.buffer.asUint8List()),
                      width: 18,
                      height: 18,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'East Hardware',
                      style: const pw.TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                pw.Text(
                  'User Logs Report',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }

  pw.Widget _buildContent() {
    return pw.Table(
      border: pw.TableBorder.symmetric(),
      columnWidths: const {
        0: pw.FixedColumnWidth(30), // ID
        1: pw.FlexColumnWidth(2), // User
        2: pw.FlexColumnWidth(1.5), // Date
        3: pw.FlexColumnWidth(1), // Time
        4: pw.FlexColumnWidth(1.5), // Action
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          children: [
            _headerCell('ID'),
            _headerCell('User'),
            _headerCell('Date'),
            _headerCell('Time'),
            _headerCell('Action'),
          ],
        ),

        // Data rows
        for (final log in logs)
          pw.TableRow(
            children: [
              _dataCell(log.id.toString()),
              _dataCell(_getUserName(log.userId)),
              _dataCell(_formatDate(log.eventTime)),
              _dataCell(_formatTime(log.eventTime)),
              _dataCell(log.event),
            ],
          ),
      ],
    );
  }

  static const pw.EdgeInsetsGeometry _cellPadding = pw.EdgeInsets.all(2.0);

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: _cellPadding,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: _cellPadding,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  String _getUserName(int userId) {
    final user = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(
        uid: '',
        firstName: 'Unknown',
        lastName: 'User',
        username: 'unknown',
        accessLevel: AccessLevel.staff,
        passwordHash: Uint8List(0),
        salt: Uint8List(0),
        loginStatus: 0,
        creationDate: '',
      ),
    );

    return '${user.firstName} ${user.lastName}';
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
