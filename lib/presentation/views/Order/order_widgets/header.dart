import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.isRestock});
  final bool isRestock;

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
        DisplayText(isRestock ? "Create Restock Order " : "Create Expense Order"),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save Order',
          onPressed: () => _handleSaveOrder(context, isRestock),
        ),
        Spacing.h4,
      ].withSpacing(() => Spacing.h16),
    );
  }

  void _handleSaveOrder(BuildContext context, bool isRestock) {
    final creationDate = DateTime.now();
    final creatorId = context.read<AuthenticationBloc>().state.user?.id;

    if (creatorId == null) {
      // Optional: Show error dialog/snack bar
      print('Error: creatorId is null.');
      return;
    }

    if (isRestock) {
      const restockExpenseType = ExpenseType(
        id: 1,
        name: 'Inventory Restock',
        archiveStatus: 0,
      );

      context.read<OrderFormBloc>()
        ..add(const ExpenseTypeChangedEvent(restockExpenseType))
        ..add(
          SaveRestockOrderRequestEvent(
            creationDate: creationDate,
            creatorId: creatorId,
          ),
        );
    } else {
      context.read<OrderFormBloc>().add(
            SaveExpenseOrderRequestEvent(
              creationDate: creationDate,
              creatorId: creatorId,
            ),
          );
    }
  }
}
