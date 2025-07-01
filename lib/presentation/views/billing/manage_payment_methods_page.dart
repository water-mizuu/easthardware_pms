import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/billing/payment_method_display/payment_method_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/billing/payment_method_display/payment_method_display_enum.dart';
import 'package:easthardware_pms/presentation/cubit/billing/payment_method_form/payment_method_form_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show DataCell, DataColumn, DataRow, DataTableSource, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_animator/scroll_animator.dart';

class ManagePaymentMethodsPage extends StatefulWidget {
  const ManagePaymentMethodsPage({super.key});

  @override
  State<ManagePaymentMethodsPage> createState() => _ManagePaymentMethodsPageState();
}

class _ManagePaymentMethodsPageState extends State<ManagePaymentMethodsPage> {
  late final AnimatedScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());

    // Listen for payment methods from the PaymentMethodListBloc
    final paymentMethodListBloc = context.read<PaymentMethodListBloc>();

    // Ensure we have the latest payment methods
    paymentMethodListBloc.add(const FetchAllPaymentMethodsEvent());

    // Initialize the display cubit with current payment methods
    context
        .read<PaymentMethodDisplayCubit>()
        .updateItems(paymentMethodListBloc.state.paymentMethods);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentMethodListBloc, PaymentMethodListState>(
        listenWhen: (prev, curr) => prev.paymentMethods != curr.paymentMethods,
        listener: (context, state) {
          context.read<PaymentMethodDisplayCubit>().updateItems(state.paymentMethods);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: AppPadding.panePadding,
              child: PageHeader(),
            ),
            Spacing.v4,
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.panePadding.horizontal / 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      PaymentMethodsListSection(),
                    ].withSpacing(() => Spacing.v16),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final access = context.select((AuthenticationBloc b) => b.state.user?.accessLevel);
    if (access != AccessLevel.administrator) {
      return const HeadingText('Payment Methods');
    }

    return Row(
      children: [
        const Text('Payment Methods', style: TextStyles.display),
        const Spacer(flex: 1),
        TextButtonFilled('New Payment Method', onPressed: () {
          _showAddPaymentMethodDialog(context);
        }),
      ].withSpacing(() => Spacing.h16),
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    unawaited(showDialog(
      context: context,
      builder: (context) {
        final bloc = context.read<PaymentMethodListBloc>();
        final existingNames = bloc.state.paymentMethods.map((pm) => pm.name).toList();

        return BlocProvider(
          create: (context) => PaymentMethodFormCubit(),
          child: Builder(
            builder: (context) {
              final formKey = context.read<PaymentMethodFormCubit>().formKey;
              return BlocListener<PaymentMethodFormCubit, PaymentMethodFormState>(
                listenWhen: (previous, current) => previous.status != current.status,
                listener: (context, state) {
                  if (state.status == FormStatus.submitting) {
                    bloc.add(AddPaymentMethodEvent(PaymentMethod(name: state.name)));
                    final authState = context.read<AuthenticationBloc>().state;
                    context.read<UserLogListBloc>().add(
                          AddUpdateEvent(
                            'Payment Method #${bloc.state.paymentMethods.length + 1}',
                            authState.user!,
                          ),
                        );
                    context.read<PaymentMethodFormCubit>().onSubmit();
                  } else if (state.status == FormStatus.submitted) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.read<PaymentMethodFormCubit>().onFormReset();
                    }
                  }
                },
                child: ContentDialog(
                  title: const Text('Add Payment Method', style: TextStyles.title),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Name', style: TextStyles.body),
                        Spacing.v4,
                        BlocBuilder<PaymentMethodFormCubit, PaymentMethodFormState>(
                          buildWhen: (previous, current) =>
                              previous.name != current.name ||
                              previous.errorMessage != current.errorMessage ||
                              previous.status != current.status,
                          builder: (context, state) {
                            final controller = TextEditingController(text: state.name);
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: state.name.length),
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextBox(
                                  controller: controller,
                                  onChanged: context.read<PaymentMethodFormCubit>().onNameChanged,
                                  placeholder: 'Enter payment method name',
                                  autofocus: true,
                                ),
                                if (state.errorMessage != null && state.status == FormStatus.error)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      state.errorMessage!,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Button(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FilledButton(
                      child: const Text('Add'),
                      onPressed: () => context.read<PaymentMethodFormCubit>().onButtonPressed(
                            existingNames: existingNames,
                            isAdding: true,
                            currentName: null,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ));
  }
}

class PaymentMethodsListSection extends StatelessWidget {
  const PaymentMethodsListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('List of Payment Methods'),
        const SearchRow(),
        const PaymentMethodsDataTable(),

        /// Blank space to allow space for scrolling past the table.
        Spacing.v12,
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class SearchRow extends StatelessWidget {
  const SearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: TextBox(
              placeholder: 'Search',
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              onChanged: (value) {
                context.read<PaymentMethodDisplayCubit>().updateSearch(value);
              },
            ),
          ),
          const SizedBox(width: 48),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class PaymentMethodsDataTable extends StatelessWidget {
  const PaymentMethodsDataTable({super.key});

  int? _getSortColumnIndex(PaymentMethodDisplaySortBy sortBy) {
    switch (sortBy) {
      case PaymentMethodDisplaySortBy.nameAscending:
      case PaymentMethodDisplaySortBy.nameDescending:
        return 0; // Index of the Name column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentMethodDisplayCubit, PaymentMethodDisplayState>(
      builder: (context, state) {
        final paymentMethodDisplayCubit = context.read<PaymentMethodDisplayCubit>();
        final filtered = state.filteredPaymentMethods;
        final allPaymentMethods = state.allPaymentMethods ?? [];

        return TableThemeData(
          child: PaginatedDataTable(
            showFirstLastButtons: true,
            showCheckboxColumn: false,
            horizontalMargin: 20,
            columnSpacing: 16,
            sortColumnIndex: _getSortColumnIndex(state.sortBy),
            sortAscending: state.sortAscending,
            checkboxHorizontalMargin: 0,
            columns: [
              DataColumn(
                label: Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 400, maxWidth: 1000),
                    child: Row(
                      children: [
                        const Text('Name', style: TextStyles.strong),
                        if (_getSortColumnIndex(state.sortBy) != 0) ...[
                          const Spacer(),
                          const Icon(
                            FluentIcons.scroll_up_down,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                onSort: (_, __) {
                  // Toggle between ascending and descending based on current sort type
                  if (state.sortBy == PaymentMethodDisplaySortBy.nameAscending ||
                      state.sortBy == PaymentMethodDisplaySortBy.nameDescending) {
                    // If already sorting by name, just toggle direction
                    paymentMethodDisplayCubit.updateSort(state.sortBy);
                  } else {
                    // If not already sorting by name, start with ascending
                    paymentMethodDisplayCubit.updateSort(PaymentMethodDisplaySortBy.nameAscending);
                  }
                },
              ),
              if (context.select((AuthenticationBloc b) => b.state.user?.accessLevel) ==
                  AccessLevel.administrator)
                DataColumn(
                  label: Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 50),
                      child: const Text('Actions', style: TextStyles.strong),
                    ),
                  ),
                ),
            ],
            source: PaymentMethodDataSource(
              context: context,
              paymentMethods: filtered ?? allPaymentMethods,
            ),
          ),
        );
      },
    );
  }
}

class PaymentMethodDataSource extends DataTableSource {
  PaymentMethodDataSource({
    required this.context,
    required this.paymentMethods,
  });

  final List<PaymentMethod> paymentMethods;
  final BuildContext context;

  @override
  DataRow? getRow(int index) {
    final accessLevel = context.read<AuthenticationBloc>().state.user?.accessLevel;
    final paymentMethod = paymentMethods[index];

    return DataRow(
      onSelectChanged: (_) {
        // View payment method details
      },
      cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              paymentMethod.name,
              style: TextStyles.body,
            ),
          ),
        ),
        if (accessLevel == AccessLevel.administrator)
          DataCell(
            Row(
              children: [
                Button(
                  child: const Text('Edit'),
                  onPressed: () {
                    _showEditPaymentMethodDialog(context, paymentMethod);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => paymentMethods.length;

  @override
  int get selectedRowCount => 0;

  void _showEditPaymentMethodDialog(BuildContext context, PaymentMethod paymentMethod) {
    unawaited(showDialog(
      context: context,
      builder: (context) {
        final bloc = context.read<PaymentMethodListBloc>();
        final existingNames = bloc.state.paymentMethods.map((pm) => pm.name).toList()
          ..remove(paymentMethod.name);

        return BlocProvider(
          create: (context) => PaymentMethodFormCubit()..onNameChanged(paymentMethod.name),
          child: Builder(
            builder: (context) {
              final formKey = context.read<PaymentMethodFormCubit>().formKey;
              return BlocListener<PaymentMethodFormCubit, PaymentMethodFormState>(
                listenWhen: (previous, current) => previous.status != current.status,
                listener: (context, state) {
                  if (state.status == FormStatus.submitting) {
                    bloc.add(UpdatePaymentMethodEvent(paymentMethod.copyWith(name: state.name)));
                    final authState = context.read<AuthenticationBloc>().state;
                    context.read<UserLogListBloc>().add(
                          AddUpdateEvent(
                            'Payment Method #${paymentMethod.id}',
                            authState.user!,
                          ),
                        );
                    context.read<NotificationCubit>().addNotification(
                          type: NotificationType.warning,
                          title: 'Notice:',
                          message:
                              '${paymentMethod.name} payment method was updated by ${authState.user!.username}.',
                          path: '',
                        );
                    context.read<PaymentMethodFormCubit>().onSubmit();
                  } else if (state.status == FormStatus.submitted) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.read<PaymentMethodFormCubit>().onFormReset();
                    }
                  }
                },
                child: ContentDialog(
                  title: Text('Edit ${paymentMethod.name}', style: TextStyles.title),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Name', style: TextStyles.body),
                        Spacing.v4,
                        BlocBuilder<PaymentMethodFormCubit, PaymentMethodFormState>(
                          buildWhen: (previous, current) =>
                              previous.name != current.name ||
                              previous.errorMessage != current.errorMessage ||
                              previous.status != current.status,
                          builder: (context, state) {
                            final controller = TextEditingController(text: state.name);
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: state.name.length),
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextBox(
                                  controller: controller,
                                  onChanged: context.read<PaymentMethodFormCubit>().onNameChanged,
                                  placeholder: 'Enter payment method name',
                                  autofocus: true,
                                ),
                                if (state.errorMessage != null && state.status == FormStatus.error)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      state.errorMessage!,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Button(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FilledButton(
                      child: const Text('Save'),
                      onPressed: () => context.read<PaymentMethodFormCubit>().onButtonPressed(
                            existingNames: existingNames,
                            isAdding: false,
                            currentName: paymentMethod.name,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ));
  }
}
