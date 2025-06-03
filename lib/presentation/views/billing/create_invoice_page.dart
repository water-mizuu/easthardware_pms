import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoiceform/invoice_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/data_cell_functions.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataRow, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateInvoicePage extends StatelessWidget {
  const CreateInvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceFormBloc(),
      child: BlocListener<InvoiceFormBloc, InvoiceFormState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        child: Container(
          color: Colors.white,
          padding: AppPadding.panePadding,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(),
              Spacing.v32,
              PageForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class PageForm extends StatelessWidget {
  const PageForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = context.read<InvoiceFormBloc>().formKey;
    return Expanded(
        flex: 3,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[40],
                            width: 1,
                          ),
                        )),
                        child: Text(
                          "Billing Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[150],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BodyText('Invoice Number *'),
                                Spacing.v8,
                                TextFormBox(readOnly: true)
                              ],
                            ),
                          ),
                          Spacing.h16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BodyText('Invoice Date *'),
                                Spacing.v8,
                                DatePicker(selected: DateTime.now())
                              ],
                            ),
                          ),
                          Spacing.h16,
                          const Spacer(),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BodyText('Customer Name *'),
                                Spacing.v8,
                                TextFormBox(),
                              ],
                            ),
                          ),
                          Spacing.h16,
                          const Spacer(flex: 2),
                          Spacing.h16,
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BodyText('Due Date *'),
                                Spacing.v8,
                                DatePicker(selected: DateTime.now()),
                              ],
                            ),
                          ),
                          Spacing.h16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BodyText('Reference Number'),
                                Spacing.v8,
                                TextFormBox(),
                              ],
                            ),
                          ),
                          Spacing.h16,
                          const Spacer(flex: 1),
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
                                TextBox(minLines: 3, maxLines: 3)
                              ],
                            ),
                          ),
                          Spacing.h8,
                        ],
                      ),
                      Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              border: Border(
                            bottom: BorderSide(color: Colors.grey[40]),
                          )),
                          child: const SubheadingText("Items")),
                      const InvoiceProductDataTable(),
                    ].withSpacing(() => Spacing.v12),
                  )),
                ],
              )
            ],
          ),
        ));
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(FluentIcons.back), onPressed: () {}),
        const DisplayText("Create Invoice"),
        const Spacer(flex: 1),
        TextButton('Save and Receive Payment', onPressed: () {}),
        TextButtonFilled('Save Invoice', onPressed: () {})
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class InvoiceProductDataTable extends StatelessWidget {
  const InvoiceProductDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(builder: (context, state) {
      final bloc = context.read<InvoiceFormBloc>();
      final products = context.read<ProductListBloc>().state.allProducts;

      return Row(
        children: [
          DataTable(
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
              DataColumn(label: Text("Discount")),
              DataColumn(label: Text("Amount")),
              DataColumn(label: Text("Actions"))
            ],
            rows: List<DataRow>.generate(
              state.products.length,
              (index) {
                final product = state.products[index];
                final units = [
                  Unit(name: product.unit, mainQuantity: 1, unitQuantity: 1),
                  ...context.read<UnitListBloc>().state.units
                ];
                final functions = InvoiceProductFunctions(
                  onProductSelected: (value) => bloc.add(ProductSelectedEvent(value, index)),
                  onDescriptionChanged: (value) =>
                      bloc.add(ProductUpdatedEvent(product.copyWith(description: value), index)),
                  onQuantityChanged: (value) =>
                      bloc.add(ProductUpdatedEvent(product.copyWith(quantity: value), index)),
                  onUnitSelected: (value) =>
                      bloc.add(ProductUpdatedEvent(product.copyWith(unit: value.name), index)),
                  onRateChanged: (value) =>
                      bloc.add(ProductUpdatedEvent(product.copyWith(rate: value), index)),
                  onAmountChanged: (value) =>
                      bloc.add(ProductUpdatedEvent(product.copyWith(amount: value), index)),
                );

                return DataRowMapper.mapInvoiceProductToRow(
                    index, product, products, units, functions);
              },
            ),
          ),
        ],
      );
    });
  }
}
