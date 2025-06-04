import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/models/data_cell_functions.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataRow, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateOrderPage extends StatelessWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderFormBloc(),
      child: BlocListener<OrderFormBloc, OrderFormState>(
        listener: (context, state) {
          // TODO: Add listener logic
        },
        child: Container(
          color: Colors.white,
          padding: AppPadding.panePadding,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrderPageHeader(),
              Spacing.v32,
              OrderPageForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderPageHeader extends StatelessWidget {
  const OrderPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () {
              context.navigate(AppRoutes.admin.order);
            }),
        const DisplayText("Create Order"),
        const Spacer(flex: 1),
        //TextButton('Save and Pay', onPressed: () {}),
        TextButtonFilled('Save Order', onPressed: () {}),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class OrderPageForm extends StatelessWidget {
  const OrderPageForm({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = context.read<OrderFormBloc>().formKey;

    return Expanded(
      flex: 3,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader("Order Information"),
            Row(
              children: [
                _OrderFormField('Payee Name *', TextFormBox()),
                Spacing.h16,
                _OrderFormField(
                    'Order Date *', DatePicker(selected: DateTime.now())),
              ],
            ),
            Row(
              children: [
                _OrderFormField('Expense Type *', TextFormBox()),
                Spacing.h16,
                _OrderFormField('Payment Method *', TextFormBox()),
              ],
            ),
            Row(
              children: [
                _OrderFormField('Reference Number', TextFormBox()),
                Spacing.h16,
                _OrderFormField(
                    'Payment Date', DatePicker(selected: DateTime.now())),
              ],
            ),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BodyText('Memo'),
                      Spacing.v8,
                      TextBox(minLines: 3, maxLines: 3),
                    ],
                  ),
                ),
              ],
            ),
            const SectionHeader("Order Items"),
            const OrderProductDataTable(),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class _OrderFormField extends StatelessWidget {
  final String label;
  final Widget input;

  const _OrderFormField(this.label, this.input);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BodyText(label),
          Spacing.v8,
          input,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[150],
        ),
      ),
    );
  }
}

class OrderProductDataTable extends StatelessWidget {
  const OrderProductDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderFormBloc, OrderFormState>(
      builder: (context, state) {
        final bloc = context.read<OrderFormBloc>();
        final products = context.read<ProductListBloc>().state.allProducts;

        return DataTable(
          columnSpacing: 20,
          dataRowMinHeight: 20,
          dataRowMaxHeight: 36,
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[40]),
          ),
          columns: const [
            DataColumn(label: Text("No.")),
            DataColumn(label: Text("Product")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Quantity")),
            DataColumn(label: Text("Rate")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Actions")),
          ],
          rows: List<DataRow>.generate(
            state.products.length,
            (index) {
              final product = state.products[index];
              final units = [
                Unit(name: product.unit, mainQuantity: 1, unitQuantity: 1),
                ...context.read<UnitListBloc>().state.units
              ];
              final functions = OrderProductFunctions(
                onProductSelected: (value) =>
                    bloc.add(ProductSelectedEvent(value, index)),
                onDescriptionChanged: (value) => bloc.add(ProductUpdatedEvent(
                    product.copyWith(description: value), index)),
                onQuantityChanged: (value) => bloc.add(ProductUpdatedEvent(
                    product.copyWith(quantity: value), index)),
                onUnitSelected: (value) => bloc.add(ProductUpdatedEvent(
                    product.copyWith(unit: value.name), index)),
                onRateChanged: (value) => bloc.add(
                    ProductUpdatedEvent(product.copyWith(rate: value), index)),
                onAmountChanged: (value) => bloc.add(ProductUpdatedEvent(
                    product.copyWith(amount: value), index)),
              );

              return DataRowMapper.mapOrderProductToRow(
                  index, product, products, units, functions);
            },
          ),
        );
      },
    );
  }
}
