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
            const restockExpenseType = ExpenseType(
              id: 0,
              name: 'Inventory Restock',
              archiveStatus: 0,
            );

            context.read<OrderFormBloc>()
              ..add(const ExpenseTypeChangedEvent(restockExpenseType))
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
