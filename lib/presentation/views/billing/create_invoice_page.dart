import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoiceform/invoice_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/box_decorations.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:scroll_animator/scroll_animator.dart';

import '../../widgets/ui/text_form_boxes.dart';

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
              Spacing.v12,
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

    return Form(
      key: formKey,
      child: Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Spacing.v8,
            Text(
              "Billing Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[150],
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Customer Name'),
                      Spacing.v8,
                      TextFormBox(
                        onChanged: (value) => context.read<InvoiceFormBloc>().add(
                              CustomerNameChangedEvent(value),
                            ),
                      ),
                    ],
                  ),
                ),
                Spacing.h12,
                const Spacer(flex: 3),
                Spacing.h12,
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Invoice Date'),
                      Spacing.v8,
                      DatePicker(
                        selected: DateTime.now(),
                        onChanged: (value) => context.read<InvoiceFormBloc>().add(
                              InvoiceDateChangedEvent(value),
                            ),
                      )
                    ],
                  ),
                ),
                Spacing.h12,
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Due Date'),
                      Spacing.v8,
                      DatePicker(
                        selected: DateTime.now(),
                        onChanged: (value) => context.read<InvoiceFormBloc>().add(
                              DueDateChangedEvent(value),
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Spacing.h12,
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Memo'),
                      Spacing.v8,
                      TextBox(
                        minLines: 3,
                        maxLines: 3,
                        onChanged: (value) =>
                            context.read<InvoiceFormBloc>().add(MemoChangedEvent(value)),
                      ),
                    ],
                  ),
                ),
                Spacing.h8,
              ],
            ),
            const TableActions(),
            const InvoiceProductTable(),
            const InvoiceSummary(),
          ].withSpacing(() => Spacing.v12),
        ),
      ),
    );
  }
}

class TableActions extends StatelessWidget {
  const TableActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(
              "Items",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[150],
              ),
            ),
            const Spacer(),
            TextButton(
              'Clear Items',
              onPressed: () {
                context.read<InvoiceFormBloc>().add(const ProductsClearedEvent());
              },
            ),
            Spacing.h12,
            TextButtonFilled(
              'Add Product',
              onPressed: () {
                context.read<InvoiceFormBloc>().add(const ProductAddedEvent());
              },
            ),
          ],
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
        IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => context.read<AuthenticationBloc>().state.user!.accessLevel ==
                    AccessLevel.administrator
                ? context.navigate(AppRoutes.admin.billing)
                : context.navigate(AppRoutes.staff.billing)),
        const DisplayText("Create Invoice"),
        const Spacer(flex: 1),
        TextButton('Save and Receive Payment', onPressed: () {}),
        TextButtonFilled('Save Invoice', onPressed: () {})
      ].withSpacing(() => Spacing.h12),
    );
  }
}

class InvoiceProductTable extends StatefulWidget {
  const InvoiceProductTable({super.key});

  @override
  State<InvoiceProductTable> createState() => _InvoiceProductTableState();
}

class _InvoiceProductTableState extends State<InvoiceProductTable> {
  late final AnimatedScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(builder: (context, state) {
      final bloc = context.read<InvoiceFormBloc>();
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[40])),
              ),
              child: Row(
                children: [
                  FormTableColumn(
                      child: const SizedBox(width: 32.0, child: Center(child: Text("#")))),
                  Expanded(flex: 2, child: FormTableColumn(child: const Text("Product"))),
                  Expanded(flex: 2, child: FormTableColumn(child: const Text("Description"))),
                  Expanded(child: FormTableColumn(child: const Text("Quantity"))),
                  Expanded(child: FormTableColumn(child: const Text("Rate"))),
                  Expanded(child: FormTableColumn(child: const Text("Amount"))),
                  const SizedBox(width: 82.0, child: Center(child: Text("Actions"))),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: _scrollController,
                  itemCount: bloc.state.products.length,
                  itemBuilder: (context, index) {
                    return FormTableRow(index: index);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class FormTableRow extends StatefulWidget {
  const FormTableRow({
    super.key,
    required this.index,
  });

  final int index;

  @override
  State<FormTableRow> createState() => _FormTableRowState();
}

class _FormTableRowState extends State<FormTableRow> {
  TextEditingController? _descriptionController;
  TextEditingController? _quantityController;
  TextEditingController? _rateController;
  TextEditingController? _amountController;
  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductListBloc>().state.allProducts;
    final bloc = context.read<InvoiceFormBloc>();
    final currentProduct = bloc.state.products[widget.index];
    return BlocListener<InvoiceFormBloc, InvoiceFormState>(
      listenWhen: (previous, current) {
        return previous.products[widget.index] != current.products[widget.index];
      },
      listener: (context, state) {
        printBoxed(
            "Index:${widget.index}\nId:${currentProduct.productId}\nDescription:${currentProduct.description}\nQuantity:${currentProduct.quantity}\nRate:${currentProduct.rate}\nAmount:${currentProduct.amount}",
            "FormBlocListener");
        _descriptionController ??= TextEditingController(text: currentProduct.description);
        _quantityController ??= TextEditingController(text: currentProduct.quantity.toString());
        _rateController ??= TextEditingController(text: currentProduct.rate.toString());
        _amountController ??= TextEditingController(text: currentProduct.amount.toStringAsFixed(2));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[40])),
        ),
        child: Row(
          children: [
            FormTableCell(
                child: SizedBox(
                    height: 32.0,
                    width: 32.0,
                    child: Center(child: Text((widget.index + 1).toString())))),
            // Field 1 - Product
            Expanded(
              flex: 2,
              // Primitive Solution to AutoSuggestBox lack of padding
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(right: BorderSide(width: 0.5, color: Colors.transparent))),
                child: AutoSuggestBox.form(
                  decoration: BoxDecorations.ghost,
                  foregroundDecoration: BoxDecorations.ghost,
                  items: [
                    for (final product in products)
                      AutoSuggestBoxItem<Product>(
                        value: product,
                        label: product.name,
                      ),
                  ],
                  onChanged: (value, reason) {
                    if (reason == TextChangedReason.cleared) {
                      // bloc.add(ProductUpdatedEvent(
                      //   // EmptyFormProduct(),
                      //   widget.index,
                      // ));
                    }
                  },
                  onSelected: (value) {
                    // If no product is currently, we select the product
                    if (currentProduct.productId == null) {
                      final formProduct = FormProduct.fromProduct(value.value!);
                      printBoxed(
                        "Selected Product: ${formProduct.productId} - ${formProduct.productName}",
                        "FormTableRow",
                      );
                      bloc.add(ProductSelectedEvent(formProduct, widget.index));
                      // Else, we update the product
                    } else if (currentProduct.productId != value.value!.id) {
                      bloc.add(ProductUpdatedEvent(
                        FormProduct.fromProduct(value.value!).copyWith(
                          description: currentProduct.description,
                          quantity: currentProduct.quantity,
                        ),
                        widget.index,
                      ));
                    } else {
                      // If the product is already selected, we do nothing
                      // This is to prevent unnecessary updates
                      return;
                    }
                  },
                  placeholder: 'Select Product',
                  placeholderStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            ),
            // Field 2 - Description
            Expanded(
                flex: 2,
                child: FormTableCell(
                  child: TextFormBoxes.ghost(
                    controller: _descriptionController,
                    enabled: currentProduct.productId != null,
                    placeholder: 'Sale Description',
                    onChanged: (value) {
                      bloc.add(ProductUpdatedEvent(
                        currentProduct.copyWith(description: value),
                        widget.index,
                      ));
                    },
                  ),
                )),
            // Field 3 - Quantity
            Expanded(
              child: FormTableCell(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          flex: 1,
                          child: TextFormBoxes.ghost(
                            controller: _quantityController,
                            placeholder: '0',
                            onChanged: (value) {
                              final quantity = double.tryParse(value) ?? 0.0;
                              bloc.add(
                                ProductUpdatedEvent(
                                  currentProduct.copyWith(
                                    quantity: quantity,
                                    amount: quantity * currentProduct.rate,
                                  ),
                                  widget.index,
                                ),
                              );
                            },
                          )),
                      if (currentProduct.productId != null)
                        Expanded(
                          flex: 2,
                          child: DropDownButton(
                            items: [
                              MenuFlyoutItem(
                                  text: Text(context
                                      .read<ProductListBloc>()
                                      .state
                                      .allProducts
                                      .firstWhere(
                                          (product) => product.id == currentProduct.productId)
                                      .mainUnit),
                                  onPressed: () {
                                    bloc.add(ProductUpdatedEvent(
                                      currentProduct.copyWith(
                                          unit: context
                                              .read<ProductListBloc>()
                                              .state
                                              .allProducts
                                              .firstWhere((product) =>
                                                  product.id == currentProduct.productId)
                                              .mainUnit),
                                      widget.index,
                                    ));
                                  }),
                              for (final unit in context
                                  .read<UnitListBloc>()
                                  .state
                                  .units
                                  .where((u) => u.productId == currentProduct.productId))
                                MenuFlyoutItem(
                                  text: Text(unit.name),
                                  onPressed: () {
                                    bloc.add(
                                      ProductUpdatedEvent(
                                        currentProduct.copyWith(unit: unit.name),
                                        widget.index,
                                      ),
                                    );
                                  },
                                ),
                            ],
                            buttonBuilder: (context, onOpen) {
                              return Button(
                                  style: ButtonStyle(
                                    padding: const WidgetStatePropertyAll(
                                      EdgeInsetsDirectional.fromSTEB(0, 5, 0, 6),
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                        side: const BorderSide(color: Colors.transparent),
                                      ),
                                    ),
                                  ),
                                  onPressed: onOpen,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(currentProduct.unit),
                                      Spacing.h12,
                                      const Icon(FluentIcons.chevron_down),
                                    ],
                                  ));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Field 4 - Rate
            Expanded(
              child: FormTableCell(
                child: TextFormBoxes.ghost(
                  controller: _rateController,
                  enabled: currentProduct.productId != null,
                  placeholder: '0.0',
                  onChanged: (value) {
                    final rate = double.tryParse(value) ?? 0.0;
                    bloc.add(
                      ProductUpdatedEvent(
                        currentProduct.copyWith(rate: rate, amount: rate * currentProduct.quantity),
                        widget.index,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Field 5 - Amount
            Expanded(
              child: FormTableCell(
                child: TextFormBoxes.ghost(
                  enabled: false,
                  placeholder: currentProduct.amount.toStringAsFixed(2),
                  onChanged: null,
                ),
              ),
            ),
            widget.index > 0
                ? SizedBox(
                    width: 82.0,
                    child: Center(
                      child: IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () => bloc.add(ProductRemovedEvent(widget.index))),
                    ),
                  )
                : const SizedBox(width: 82.0)
          ],
        ),
      ),
    );
  }
}

class InvoiceSummary extends StatelessWidget {
  const InvoiceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(builder: (context, state) {
      final total = state.products
          .fold<double>(0.0, (previousValue, element) => previousValue + (element.amount));

      return Row(
        children: [
          const Spacer(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal"),
                      Text("\$${state.subtotal?.toStringAsFixed(2)}"),
                    ],
                  ),
                  Spacing.v16,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Discount"),
                      const Spacer(),
                      Expanded(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 2, child: TextFormBox()),
                              Expanded(
                                flex: 2,
                                child: ComboBox(
                                  elevation: 2,
                                  isExpanded: true,
                                  value: state.discountType,
                                  onChanged: (value) => context
                                      .read<InvoiceFormBloc>()
                                      .add(DiscountTypeChangedEvent(value!)),
                                  items: const [
                                    ComboBoxItem(
                                      value: DiscountType.percentage,
                                      child: Text(
                                        "Percentage",
                                      ),
                                    ),
                                    ComboBoxItem(
                                      value: DiscountType.value,
                                      child: Text(
                                        "Amount",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.v16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StrongText("Total"),
                      StrongText("Php. ${total.toStringAsFixed(2)}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
