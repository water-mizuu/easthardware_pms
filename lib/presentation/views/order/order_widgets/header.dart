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
    final isEditMode = context.select((OrderFormBloc b) => b.state.orderId != null);

    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () {
            context.navigate(AppRoutes.admin.order);
          },
        ),
        DisplayText(isRestock
            ? (isEditMode ? "Edit Restock Order " : "Create Restock Order ")
            : (isEditMode ? "Edit Expense Order " : "Create Expense Order ")),
        const Spacer(flex: 1),
        TextButtonFilled(
          isEditMode ? 'Update Order' : 'Save Order',
          onPressed: () => _handleSaveOrder(context, isRestock),
        ),
        Spacing.h4,
      ].withSpacing(() => Spacing.h16),
    );
  }

  void _handleSaveOrder(BuildContext context, bool isRestock) {
    final formBloc = context.read<OrderFormBloc>();
    final creationDate = DateTime.now();
    final creatorId = context.read<AuthenticationBloc>().state.user?.id;

    if (creatorId == null) {
      // Optional: Show error dialog/snack bar
      if (kDebugMode) {
        print('Error: creatorId is null.');
      }
      showNotification.error(
        title: 'Error',
        message: 'You must be logged in to save an order.',
      );
      return;
    }

    // Check for empty items before submitting
    if (isRestock) {
      // For restock order
      final restockExpenseType = (context.read<ExpenseTypeListBloc>().state.expenseTypes)
          .firstWhere((type) => type.name == 'Inventory Restock');

      formBloc
        ..add(ExpenseTypeChangedEvent(restockExpenseType))
        ..add(
          SaveRestockOrderRequestEvent(
            creationDate: creationDate,
            creatorId: creatorId,
          ),
        );
    } else {
      // For expense orders
      formBloc.add(
        SaveExpenseOrderRequestEvent(
          creationDate: creationDate,
          creatorId: creatorId,
        ),
      );
    }
  }
}
