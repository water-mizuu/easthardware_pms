import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoiceform/invoice_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/auto_auto_suggest_box.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/decorations.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/loading_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_animator/scroll_animator.dart';

import '../../widgets/ui/text_form_boxes.dart';

/// Spacing Guidelines
/// - Spacing between fields: 12.0
/// - Spacing between sections: 16.0
/// - Horizontal spacing between elements: 8.0
class EditInvoicePage extends StatelessWidget {
  const EditInvoicePage({required this.invoice, super.key});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final invoiceListBloc = context.read<InvoiceListBloc>().state;
        final products = invoiceListBloc.invoiceProducts //
            .where((p) => p.invoiceId == invoice.id)
            .toList();

        return InvoiceFormBloc.fromExistingInvoice(invoice, products);
      },
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<InvoiceFormBloc, InvoiceFormState>(
              listener: (context, state) {
                if (state.status == FormStatus.submitting) {
                  final invoice = state.copyWith().toInvoice();

                  final products = state.products //
                      .map((product) => product.toInvoiceProduct())
                      .toList();
                  context.read<InvoiceListBloc>().add(EditInvoiceEvent(invoice, products));
                } else if (state.status == FormStatus.error) {
                  unawaited(showSingleDialog(
                    (dialogContext) => ContentDialog(
                      title: const Text(
                        'Incomplete Details ',
                        style: TextStyles.subtitle,
                      ),
                      content: Text(state.dialogErrorMessage ?? ''),
                      actions: [
                        FilledButton(
                          child: const Text('OK'),
                          onPressed: () {
                            dialogContext.pop();
                          },
                        ),
                      ],
                    ),
                  ).whenComplete(() {
                    if (!context.mounted) return;

                    context.read<InvoiceFormBloc>().add(const DialogBoxClosedEvent());
                  }));
                }
              },
            ),
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (previous, current) =>
                  previous.latest != current.latest && current.latest != null,
              listener: (context, state) {
                final latest = state.latest!;
                final authState = context.read<AuthenticationBloc>().state;
                final formState = context.read<InvoiceFormBloc>().state;

                switch (formState.action) {
                  case InvoicePostAction.create:
                    context.read<InvoiceFormBloc>().add(const FormSubmittedEvent());
                    break;

                  case InvoicePostAction.payment:
                    if (authState.user!.accessLevel == AccessLevel.administrator) {
                      context.navigateWithExtra(AppRoutes.admin.createPayment.withInvoice, latest);
                    } else {
                      // context.navigateWithExtra(AppRoutes.staff.receivePayment, latest);
                    }
                    break;

                  case InvoicePostAction.none:
                    // Update Product Stocks
                    context.read<ProductListBloc>().add(const LoadAllProductsEvent());
                    // Add UserLog
                    context
                        .read<UserLogListBloc>()
                        .add(AddUpdateEvent('Invoice #${latest.id}', authState.user!));
                    context.read<UserLogListBloc>().add(const LoadUserLogsEvent());

                    showNotification(
                      title: "Success",
                      message: "Invoice #${latest.id} has been successfully updated.",
                      severity: InfoBarSeverity.success,
                    );
                    final route = authState.user!.accessLevel == AccessLevel.administrator
                        ? AppRoutes.admin.billing
                        : AppRoutes.staff.billing;
                    context.navigate(route);
                    break;
                }
              },
            ),
          ],
          child: Stack(
            children: [
              const Padding(
                padding: AppPadding.panePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(),
                    Spacing.v16,
                    PageForm(),
                  ],
                ),
              ),
              if (context.select((InvoiceFormBloc b) => b.state.status) == FormStatus.submitting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: const LoadingPage(),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class PageForm extends StatefulWidget {
  const PageForm({
    super.key,
  });

  @override
  State<PageForm> createState() => _PageFormState();
}

class _PageFormState extends State<PageForm> {
  late final TextEditingController _customerNameController;
  late int? _invoiceId;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _invoiceId = null;

    _customerNameController.addListener(() {
      final newName = _customerNameController.text;

      context.read<InvoiceFormBloc>().add(CustomerNameChangedEvent(newName));
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final id = context.watch<InvoiceFormBloc>().state.invoiceId;
    if (_invoiceId != id) {
      final customerName = context.read<InvoiceFormBloc>().state.customerName;
      _customerNameController.text = customerName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[40], width: 1),
                ),
              ),
              child: const Text("Billing Information", style: TextStyles.title),
            ),
            // Form Row 1 - Customer Name
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
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        controller: _customerNameController,
                        onChanged: (value) => context //
                            .read<InvoiceFormBloc>()
                            .add(CustomerNameChangedEvent(value)),
                      ),
                    ],
                  ),
                ),
                Spacing.h12,
                const Spacer(flex: 3),
                Spacing.h12,
              ],
            ),
            // Form Row 2 - Invoice and Due Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Invoice Date'),
                      Spacing.v8,
                      BorderedDatePicker(
                        selected: context.select((InvoiceFormBloc bloc) => bloc.state.invoiceDate),
                        onChanged: (value) =>
                            context.read<InvoiceFormBloc>().add(InvoiceDateChangedEvent(value)),
                      ),
                      if (context.watch<InvoiceFormBloc>().state.invoiceDateErrorMessage != null)
                        Text(
                          context.watch<InvoiceFormBloc>().state.invoiceDateErrorMessage!,
                          style: TextStyles.error,
                        ),
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
                      BorderedDatePicker(
                        selected: context.select((InvoiceFormBloc bloc) => bloc.state.dueDate),
                        onChanged: (value) =>
                            context.read<InvoiceFormBloc>().add(DueDateChangedEvent(value)),
                      ),
                      if (context.watch<InvoiceFormBloc>().state.dueDateErrorMessage != null)
                        Text(
                          context.watch<InvoiceFormBloc>().state.dueDateErrorMessage!,
                          style: TextStyles.error,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Spacing.h12,
              ],
            ),
            const TableActions(),
            const Expanded(flex: 3, child: InvoiceProductTable()),
            const Expanded(flex: 2, child: InvoiceSummary()),
          ].withSpacing(() => Spacing.v12),
        ),
      ),
    );
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
        const DisplayText("Edit Invoice"),
        const Spacer(flex: 1),
        TextButton(
          'Save and Receive Payment',
          onPressed: () {
            final creationDate = DateTime.now();
            final creatorId = context.read<AuthenticationBloc>().state.user?.id;
            context.read<InvoiceFormBloc>().add(
                  SaveInvoiceRequestEvent(
                    creationDate: creationDate,
                    creatorId: creatorId!,
                    action: InvoicePostAction.payment,
                  ),
                );
          },
        ),
        TextButtonFilled(
          'Update Invoice',
          onPressed: () {
            final creationDate = DateTime.now();
            final creatorId = context.read<AuthenticationBloc>().state.user?.id;
            context.read<InvoiceFormBloc>().add(
                  SaveInvoiceRequestEvent(
                    creationDate: creationDate,
                    creatorId: creatorId!,
                    action: InvoicePostAction.none,
                  ),
                );
          },
        ),
      ].withSpacing(() => Spacing.h12),
    );
  }
}

class TableActions extends StatelessWidget {
  const TableActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          const Text("Items", style: TextStyles.title),
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
      ),
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
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(
      builder: (context, state) {
        final bloc = context.read<InvoiceFormBloc>();
        return Column(
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
                    child: const SizedBox(
                      width: 32.0,
                      child: Center(child: Text("#", style: TextStyles.tableHeader)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormTableColumn(
                      child: const Text("PRODUCT", style: TextStyles.tableHeader),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormTableColumn(
                      child: const Text("DESCRIPTION", style: TextStyles.tableHeader),
                    ),
                  ),
                  Expanded(
                    child: FormTableColumn(
                      child: const Text("QUANTITY", style: TextStyles.tableHeader),
                    ),
                  ),
                  Expanded(
                    child: FormTableColumn(
                      child: const Text("RATE", style: TextStyles.tableHeader),
                    ),
                  ),
                  Expanded(
                    child: FormTableColumn(
                      child: const Text("AMOUNT", style: TextStyles.tableHeader),
                    ),
                  ),
                  const SizedBox(
                    width: 82.0,
                    child: Center(
                      child: Text("ACTIONS", style: TextStyles.tableHeader),
                    ),
                  ),
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
        );
      },
    );
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
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();

    final initialProduct = context.read<InvoiceFormBloc>().state.products[widget.index];

    _descriptionController = TextEditingController(text: initialProduct.description ?? '');
    _quantityController = TextEditingController(text: initialProduct.quantity.toString());
    _rateController = TextEditingController(text: initialProduct.rate.toString());

    _descriptionController.addListener(() {
      final bloc = context.read<InvoiceFormBloc>();
      final currentProduct = bloc.state.products[widget.index];

      final newValue = _descriptionController.text;
      if (currentProduct.description != newValue) {
        bloc.add(ProductUpdatedEvent(
          index: widget.index,
          product: currentProduct.copyWith(description: newValue),
        ));
      }
    }); // We no longer need a listener for product name changes
    // since we're handling selections directly with onSelected and onChanged

    _quantityController.addListener(() {
      final bloc = context.read<InvoiceFormBloc>();
      final currentProduct = bloc.state.products[widget.index];

      final newValue = int.tryParse(_quantityController.text) ?? 0;
      if (currentProduct.quantity != newValue) {
        final reference = context
            .read<ProductListBloc>()
            .state
            .allProducts
            .firstWhere((p) => p.id == initialProduct.productId);
        bloc.add(ProductUpdatedEvent(
          index: widget.index,
          product: currentProduct.copyWith(quantity: newValue),
          reference: currentProduct.productId == null
              ? null
              : context
                  .read<ProductListBloc>()
                  .state
                  .allProducts
                  .firstWhere((p) => p.id == currentProduct.productId)
                  .copyWith(quantity: reference.quantity + initialProduct.quantity),
        ));
      }
    });

    _rateController.addListener(() {
      final bloc = context.read<InvoiceFormBloc>();
      final currentProduct = bloc.state.products[widget.index];

      final newValue = double.tryParse(_rateController.text) ?? 0;
      if (currentProduct.rate != newValue) {
        final reference = context
            .read<ProductListBloc>()
            .state
            .allProducts
            .firstWhere((p) => p.id == initialProduct.productId);

        bloc.add(ProductUpdatedEvent(
          index: widget.index,
          product: currentProduct.copyWith(rate: newValue),
          reference: currentProduct.productId == null
              ? null
              : context
                  .read<ProductListBloc>()
                  .state
                  .allProducts
                  .firstWhere(
                    (p) => p.id == currentProduct.productId,
                  )
                  .copyWith(
                    quantity: reference.quantity + initialProduct.quantity,
                  ),
        ));
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(
      buildWhen: (previous, current) {
        return previous.products != current.products ||
            previous.products[widget.index] != current.products[widget.index];
      },
      builder: (context, state) {
        final products = context.read<ProductListBloc>().state.allProducts;
        final bloc = context.read<InvoiceFormBloc>();
        final currentFormProduct =
            state.products[widget.index]; // Only update controller text if it has changed
        final newDescription = currentFormProduct.description ?? '';
        final newQuantity = currentFormProduct.quantity % 1 == 0
            ? currentFormProduct.quantity.toInt().toString()
            : currentFormProduct.quantity.toString();

        final newRate = currentFormProduct.rate % 1 == 0
            ? currentFormProduct.rate.toInt().toString()
            : currentFormProduct.rate.toString();

        if (_descriptionController.text != newDescription) {
          _descriptionController.text = newDescription;
        }

        if (_quantityController.text != newQuantity) {
          _quantityController.text = newQuantity;
        }

        if (_rateController.text != newRate) {
          _rateController.text = newRate;
        }

        return Container(
          decoration: BoxDecoration(
            color: currentFormProduct.errorMessage != null
                ? Colors.errorSecondaryColor
                : widget.index % 2 == 0
                    ? const Color(0xFFFAFAFA)
                    : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[40])),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FormTableCell(
                    child: SizedBox(
                      height: 32.0,
                      width: 32.0,
                      child: Center(
                        child: Text(
                          (widget.index + 1).toString(),
                        ),
                      ),
                    ),
                  ),
                  // Field 1 - Product
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(width: 0.5, color: Colors.transparent),
                        ),
                      ),
                      child: AutoAutoSuggestBox.form(
                        // Set placeholder text when no product is selected
                        placeholder: 'Select Product',
                        // Use a controller just to display the initial text, but don't react to its changes
                        controller: TextEditingController(text: currentFormProduct.productName),
                        decoration: BoxDecorations.ghost,
                        foregroundDecoration: BoxDecorations.ghost,
                        items: [
                          for (final product in products)
                            AutoSuggestBoxItem<Product>(
                              value: product,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text(product.name, overflow: TextOverflow.ellipsis)),
                                    Text(
                                      '${product.quantity.toString()} ${product.mainUnit}',
                                      style: product.quantity < product.reorderPoint!
                                          ? TextStyles.error.merge(TextStyles.tooltip)
                                          : TextStyles.onSurface.merge(TextStyles.tooltip),
                                    ),
                                  ],
                                ),
                              ),
                              label: product.name,
                            ),
                        ],
                        onChanged: (value, reason) {
                          if (reason == TextChangedReason.cleared) {
                            // Clear the controllers when product is cleared
                            _descriptionController.clear();
                            _quantityController.clear();
                            _rateController.clear();
                            return bloc.add(
                              ProductUpdatedEvent(
                                product: const EmptyFormProduct().copyWith(productId: null),
                                index: widget.index,
                              ),
                            );
                          }
                          if (reason == TextChangedReason.userInput) {
                            for (final product in products) {
                              if (product.name.toLowerCase() == value.toLowerCase()) {
                                final formProduct = FormProduct.fromProduct(product)
                                    .copyWith(quantity: currentFormProduct.quantity);
                                return bloc.add(
                                  ProductUpdatedEvent(
                                    product: formProduct,
                                    index: widget.index,
                                    reference: product,
                                  ),
                                );
                              }
                            }
                            bloc.add(
                              ProductUpdatedEvent(
                                product: const EmptyFormProduct().copyWith(
                                  productName: value,
                                  productId: null,
                                  description: currentFormProduct.description,
                                  quantity: currentFormProduct.quantity,
                                ),
                                index: widget.index,
                              ),
                            );
                          }
                        },
                        onSelected: (value) {
                          if (currentFormProduct.productId == null) {
                            final formProduct = FormProduct.fromProduct(value.value!);
                            bloc.add(ProductSelectedEvent(formProduct, widget.index));
                          } else if (currentFormProduct.productId != value.value!.id) {
                            bloc.add(
                              ProductUpdatedEvent(
                                product: FormProduct.fromProduct(value.value!).copyWith(
                                  description: currentFormProduct.description,
                                  quantity: currentFormProduct.quantity,
                                ),
                                index: widget.index,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  // Field 2 - Description
                  Expanded(
                    flex: 2,
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        inputFormatters: [LengthLimitingTextInputFormatter(120)],
                        controller: _descriptionController,
                        placeholder: 'Product Description',
                      ),
                    ),
                  ),
                  // Field 3 - Quantity
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 8.0),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            width: 0.5,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                flex: 1,
                                child: TextFormBoxes.ghost(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  style: TextStyles.onSurface,
                                  controller: _quantityController,
                                  placeholder: '0',
                                  placeholderStyle: currentFormProduct.productId == null
                                      ? TextStyles.onSurfaceVariant
                                      : TextStyles.onSurface,
                                )),
                            if (currentFormProduct.productId == null)
                              const Spacer(flex: 2)
                            else
                              Expanded(
                                flex: 2,
                                child: _unitDropdown(context, currentFormProduct, bloc, products),
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: TextStyles.onSurface,
                        controller: _rateController,
                        placeholder: '0.0',
                        placeholderStyle: currentFormProduct.productId == null
                            ? TextStyles.onSurfaceVariant
                            : TextStyles.onSurface,
                      ),
                    ),
                  ),
                  // Field 5 - Amount (read-only, calculated field)
                  Expanded(
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        enabled: false,
                        placeholder: CurrencyFormatter.full(currentFormProduct.amount),
                        placeholderStyle: currentFormProduct.productId == null
                            ? TextStyles.onSurfaceVariant
                            : TextStyles.onSurface,
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
              if (currentFormProduct.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 4.0),
                  child: Text(
                    currentFormProduct.errorMessage!,
                    style: TextStyles.error,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _unitDropdown(
    BuildContext context,
    FormProduct currentFormProduct,
    InvoiceFormBloc bloc,
    List<Product> products,
  ) {
    final allProducts = context.watch<ProductListBloc>().state.allProducts;
    final currentProduct = allProducts //
        .where((p) => p.id == currentFormProduct.productId)
        .firstOrNull;
    if (currentProduct == null) {
      printBoxed(
        'Current product not found for ID: ${currentFormProduct.productId}',
        'unitDropdown',
      );
      return const SizedBox.shrink();
    }
    final currentProductUnits = context
        .watch<UnitListBloc>()
        .state
        .units
        .where((u) => u.productId == currentProduct.id)
        .toList();

    return DropDownButton(
      items: [
        MenuFlyoutItem(
            text: Text(currentProduct.mainUnit),
            onPressed: () {
              bloc.add(
                ProductUpdatedEvent(
                  product: currentFormProduct.copyWith(
                    // Primitive Solution to get correct amount computation
                    unitId: null,
                    conversionFactor: null,
                    rate: currentProduct.salePrice,
                    unit: currentProduct.mainUnit,
                  ),
                  index: widget.index,
                  reference: currentProduct,
                ),
              );
            }),
        for (final unit in currentProductUnits)
          MenuFlyoutItem(
            text: Text(unit.name),
            onPressed: () {
              bloc.add(
                ProductUpdatedEvent(
                  product: currentFormProduct.copyWith(
                    unit: unit.name,
                    unitId: unit.id,
                    // Primitive Solution to get correct amount computation
                    rate: currentProduct.salePrice,
                    conversionFactor: unit.mainQuantity / unit.unitQuantity,
                  ),
                  index: widget.index,
                  reference: currentProduct,
                ),
              );
            },
          ),
      ],
      buttonBuilder: (context, onOpen) {
        // Determine the correct unit name to display
        var displayUnitName = currentFormProduct.unit;

        // If the unit is a numeric value (or looks like an ID), try to find the real unit name
        if (displayUnitName == '0' || int.tryParse(displayUnitName) != null) {
          // First try to find the unit in the product's units
          final matchingUnit =
              currentProductUnits.where((unit) => unit.id == currentFormProduct.unitId).firstOrNull;

          if (matchingUnit != null) {
            // If we find a matching unit, use its name
            displayUnitName = matchingUnit.name;
          } else {
            // If no matching unit found, fall back to product's main unit
            displayUnitName = currentProduct.mainUnit;
          }
        }

        return Button(
          style: ButtonStyles.ghost,
          onPressed: onOpen,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                displayUnitName,
                overflow: TextOverflow.ellipsis,
              ),
              Spacing.h12,
              const Icon(FluentIcons.chevron_down, size: 8.0),
            ],
          ),
        );
      },
    );
  }
}

class InvoiceSummary extends StatefulWidget {
  const InvoiceSummary({super.key});

  @override
  State<InvoiceSummary> createState() => _InvoiceSummaryState();
}

class _InvoiceSummaryState extends State<InvoiceSummary> {
  late final TextEditingController _memoController;
  late final TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController();
    _discountController = TextEditingController();

    _memoController.addListener(() {
      final newMemo = _memoController.text;
      context.read<InvoiceFormBloc>().add(MemoChangedEvent(newMemo));
    });

    _discountController.addListener(() {
      final discount = double.tryParse(_discountController.text) ?? 0.0;
      final newDiscount = discount % 1 == 0 ? discount.toInt().toString() : discount.toString();
      context.read<InvoiceFormBloc>().add(DiscountChangedEvent(discount));
      _discountController.value = _discountController.value.copyWith(text: newDiscount);
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceFormBloc, InvoiceFormState>(builder: (context, state) {
      final subtotal = state.subtotal ?? 0.0;
      final discount = state.discount ?? 0.0;
      final total = state.amountDue;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BodyText('Memo'),
                Spacing.v8,
                TextBox(
                  controller: _memoController,
                  minLines: 3,
                  maxLines: 3,
                  onChanged: (value) =>
                      context.read<InvoiceFormBloc>().add(MemoChangedEvent(value)),
                ),
              ],
            ),
          ),
          Spacing.h8,
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
                      Text(
                        CurrencyFormatter.full(subtotal),
                        style: TextStyles.onSurface,
                      ),
                    ],
                  ),
                  Spacing.v16,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Discount"),
                      Spacing.h12,
                      Expanded(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormBox(
                                  controller: _discountController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                ),
                              ),
                              Spacing.h4,
                              Button(
                                style: state.discountType == DiscountType.value
                                    ? ButtonStyles.filled
                                    : ButtonStyles.outlined,
                                onPressed: () {
                                  context.read<InvoiceFormBloc>().add(
                                        const DiscountTypeChangedEvent(
                                          DiscountType.value,
                                        ),
                                      );
                                },
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Text("."),
                                ),
                              ),
                              Spacing.h4,
                              Button(
                                style: state.discountType == DiscountType.percentage
                                    ? ButtonStyles.filled
                                    : ButtonStyles.outlined,
                                onPressed: () {
                                  context.read<InvoiceFormBloc>().add(
                                        const DiscountTypeChangedEvent(
                                          DiscountType.percentage,
                                        ),
                                      );
                                },
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Text("%"),
                                ),
                              ),
                              const Spacer(flex: 3),
                              Center(
                                child: state.discountType == DiscountType.percentage
                                    ? Text(
                                        "${discount > 0 ? '-' : ''} ${CurrencyFormatter.full((discount / 100 * subtotal))}",
                                        style: TextStyles.onSurface,
                                      )
                                    : Text(
                                        "${discount > 0 ? '-' : ''} ${CurrencyFormatter.full(discount)}",
                                        style: TextStyles.onSurface,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.discountErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        state.discountErrorMessage!,
                        style: TextStyles.error,
                      ),
                    ),
                  Spacing.v16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StrongText("Total"),
                      StrongText(CurrencyFormatter.full(total)),
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
