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
    final state = formBloc.state;
    if (isRestock) {
      // For restock orders
      if (state.products != null && state.products!.isNotEmpty) {
        final anyEmpty = state.products!.any((product) =>
            product.productId == null &&
            product.quantity <= 0 &&
            product.rate <= 0 &&
            (product.description == null || product.description!.isEmpty));

        if (state.products!.length == 1 && anyEmpty) {
          showNotification.warning(
            title: 'Warning',
            message: 'Please add at least one product to the order.',
          );
          return;
        }
      }

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
      if (state.orderItems != null && state.orderItems!.isNotEmpty) {
        // Check if any items have been added or if they're all empty
        final allEmpty = state.orderItems!.any((item) =>
            (item.name == null || item.name!.isEmpty) &&
            item.quantity <= 0 &&
            item.rate <= 0 &&
            (item.description == null || item.description!.isEmpty));

        if (state.orderItems!.length == 1 && allEmpty) {
          showNotification.warning(
            title: 'Warning',
            message: 'Please add at least one item to the order.',
          );
          return;
        }
      }

      // Continue with saving expense order
      formBloc.add(
        SaveExpenseOrderRequestEvent(
          creationDate: creationDate,
          creatorId: creatorId,
        ),
      );
    }
  }
}
