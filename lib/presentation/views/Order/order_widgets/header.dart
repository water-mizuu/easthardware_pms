import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final isRestock = context.select((OrderFormBloc b) => b.state.orderType == OrderType.restock);

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
      if (kDebugMode) {
        print('Error: creatorId is null.');
      }
      showNotification.success(
        title: 'Error',
        message: 'You must be logged in to save an order.',
      );
      return;
    }

    if (isRestock) {
      final restockExpenseType = (context.read<ExpenseTypeListBloc>().state.expenseTypes)
          .firstWhere((type) => type.name == 'Inventory Restock');

      context.read<OrderFormBloc>()
        ..add(ExpenseTypeChangedEvent(restockExpenseType))
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
