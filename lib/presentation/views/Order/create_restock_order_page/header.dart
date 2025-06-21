part of '../create_restock_order_page.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () {
            context.navigate(AppRoutes.admin.order);
          },
        ),
        const DisplayText("Create Restock Order "),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save Order',
          onPressed: () {
            final creationDate = DateTime.now();
            final creatorId = context.read<AuthenticationBloc>().state.user?.id;

            /// The expense type is hardcoded to be 'Inventory Restock'
            ///   for restock orders.
            final restockExpenseType = context
                .read<ExpenseTypeListBloc>()
                .state
                .expenseTypes
                .where((e) => e.id == 0)
                .firstOrNull;
            if (restockExpenseType == null) {
              showNotification.error(
                title: 'Expense Type not found',
                message: 'The expense type for restock orders is not defined.',
              );
              return;
            }

            context.read<OrderFormBloc>()
              ..add(ExpenseTypeChangedEvent(restockExpenseType))
              ..add(
                SaveRestockOrderRequestEvent(
                  creationDate: creationDate,
                  creatorId: creatorId!,
                ),
              );
          },
        ),
        Spacing.h4,
      ].withSpacing(() => Spacing.h16),
    );
  }
}
