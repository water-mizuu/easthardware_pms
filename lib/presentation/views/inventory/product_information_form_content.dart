import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/'
    'category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/'
    'product_form/product_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_unit.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/uuid.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const spacingBetweenNameAndForm = Spacing.v4;

class ProductInformationFormContent extends StatefulWidget {
  const ProductInformationFormContent({super.key});

  @override
  State<ProductInformationFormContent> createState() => _ProductInformationFormContentState();
}

class _ProductInformationFormContentState extends State<ProductInformationFormContent> {
  /// Key to invalidate the form body when the form status is initial.
  late ValueKey<int> _bodyKey;

  @override
  void initState() {
    super.initState();

    /// Initialize the body key with the current form state hash code.
    _bodyKey = ValueKey(context.read<ProductFormBloc>().state.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormBloc, ProductFormState>(
      listenWhen: (p, c) =>
          p.formStatus == FormStatus.loading && //
          c.formStatus == FormStatus.initial,
      listener: (context, state) {
        /// Invalidate the form when the form status is initial.
        /// This is necessary to ensure that the form is rebuilt with the latest state.
        /// This is useful when the form is reset or when the user navigates back to the form.
        setState(() {
          _bodyKey = ValueKey(state.hashCode);
        });
      },
      child: Form(
        key: context.read<ProductFormBloc>().formKey,
        child: AnimatedSingleChildScrollView(
          child: Padding(
            padding: AppPadding.a16,
            child: Container(
              padding: AppPadding.panePadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
              ),
              key: _bodyKey,
              child: LayoutMode.builder(
                (context, layoutMode, keys) => switch (layoutMode) {
                  LayoutMode.wide => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: LeftColumn(key: keys['leftColumn'])),
                        Spacing.h16,
                        Expanded(child: RightColumn(key: keys['rightColumn'])),
                      ],
                    ),
                  LayoutMode.constrained || LayoutMode.compact => FocusTraversalGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LeftColumn(key: keys['leftColumn']),
                          Spacing.v16,
                          RightColumn(key: keys['rightColumn']),
                        ],
                      ),
                    ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LeftColumn extends StatelessWidget {
  const LeftColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BasicInformationSection(),
          Spacing.v16,
          StockKeepingInformationSection(),
        ],
      ),
    );
  }
}

class RightColumn extends StatelessWidget {
  const RightColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: const Column(
        children: [
          SaleInformationSection(),
          Spacing.v16,
          OrderInformationSection(),
          Spacing.v16,
          SecondaryUnitsSection(),
        ],
      ),
    );
  }
}

class SaleInformationSection extends StatelessWidget with ProductFormValidator {
  const SaleInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sale Information', style: TextStyles.title),
        Spacing.v16,
        const BodyText('Sale Price'),
        Spacing.v4,
        TextFormBox(
          prefix: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('₱', style: TextStyles.onSurfaceVariant.merge(TextStyles.body)),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          initialValue: context.read<ProductFormBloc>().state.price == 0
              ? ''
              : context.read<ProductFormBloc>().state.price.toString(),
          validator: validateProductPrice,
          onChanged: (value) {
            context
                .read<ProductFormBloc>()
                .add(PriceFieldChangedEvent(double.tryParse(value) ?? 0));
          },
        ),
      ],
    );
  }
}

class OrderInformationSection extends StatelessWidget with ProductFormValidator {
  const OrderInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Order Information'),
        Spacing.v16,
        const BodyText('Order Cost'),
        Spacing.v4,
        TextFormBox(
          prefix: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('₱', style: TextStyles.onSurfaceVariant.merge(TextStyles.body)),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          initialValue: context.read<ProductFormBloc>().state.cost == 0
              ? ''
              : context.read<ProductFormBloc>().state.cost.toString(),
          validator: validateProductCost,
          onChanged: (value) {
            context.read<ProductFormBloc>().add(CostFieldChangedEvent(double.tryParse(value) ?? 0));
          },
        ),
      ],
    );
  }
}

class BasicInformationSection extends StatelessWidget {
  const BasicInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Basic Information', style: TextStyles.title),
        Spacing.v16,
        BasicInformationFields(),
      ],
    );
  }
}

class StockKeepingInformationSection extends StatelessWidget {
  const StockKeepingInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Stock Keeping Information', style: TextStyles.title),
        Spacing.v16,
        StockKeepingFields(),
      ],
    );
  }
}

class StockKeepingFields extends StatelessWidget {
  const StockKeepingFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        CriticalLevelField(),
        ReorderDelayFields(),
        DeadFastStockFields(),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class BasicInformationFields extends StatelessWidget {
  const BasicInformationFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProductNameField(),
        const StockKeepingUnitField(),
        const CategoryField(),
        const DescriptionField(),
        const QuantityUnitFields(),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ProductNameField extends StatelessWidget with ProductFormValidator {
  const ProductNameField({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductListBloc>().state.allProducts;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Product Name'),
        Spacing.v4,
        TextFormBox(
          autofocus: true,
          initialValue: context.read<ProductFormBloc>().state.name,
          validator: (value) => validateProductName(
            value,
            products.map((e) => e.name).toList()..remove(value),
          ),
          onChanged: (value) {
            final bloc = context.read<ProductFormBloc>();
            bloc.add(NameFieldChangedEvent(value));
            bloc.add(SkuFieldChangedEvent(UUID.generate(value)));
          },
        )
      ],
    );
  }
}

class StockKeepingUnitField extends StatelessWidget {
  const StockKeepingUnitField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Stock Keeping Unit (SKU)'),
        Spacing.v4,
        TextFormBox(
          initialValue: context.watch<ProductFormBloc>().state.sku,
          placeholder: context.read<ProductFormBloc>().state.sku,
          onChanged: (value) {
            context.read<ProductFormBloc>().add(SkuFieldChangedEvent(value));
          },
        )
      ],
    );
  }
}

class CategoryField extends StatelessWidget with ProductFormValidator {
  const CategoryField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Category'),
        Spacing.v4,
        BlocBuilder<CategoryListBloc, CategoryListState>(
          builder: (context, state) => AutoSuggestBox.form(
            controller:
                TextEditingController(text: context.read<ProductFormBloc>().state.categoryName),
            validator: validateProductCategory,
            items: [
              for (final category in state.categories)
                AutoSuggestBoxItem(value: category, label: category.name),
            ],
            onChanged: (value, reason) {
              context.read<ProductFormBloc>().add(CategoryFieldChangedEvent(value));
            },
            onSelected: (value) {
              context.read<ProductFormBloc>().add(CategoryIdChangedEvent(value.value!.id!));
            },
          ),
        )
      ],
    );
  }
}

class DescriptionField extends StatelessWidget {
  const DescriptionField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Description'),
        Spacing.v4,
        TextFormBox(
          minLines: 2,
          maxLines: 2,
          initialValue: context.read<ProductFormBloc>().state.description,
          onChanged: (value) {
            context.read<ProductFormBloc>().add(DescriptionChangedEvent(value));
          },
        )
      ],
    );
  }
}

/// Custom Field Implemented as to meet the requirements
/// This field shall automatically generate a critical level value
/// based on the quantity of the product
class CriticalLevelField extends StatefulWidget {
  const CriticalLevelField({super.key});

  @override
  State<CriticalLevelField> createState() => _CriticalLevelFieldState();
}

class _CriticalLevelFieldState extends State<CriticalLevelField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    final bloc = context.read<ProductFormBloc>();
    _controller = TextEditingController(text: bloc.state.criticalLevel.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductFormBloc, ProductFormState>(
      listenWhen: (prev, curr) {
        return prev.criticalLevel != curr.criticalLevel && !curr.isCriticalLevelEdited;
      },
      listener: (context, state) {
        _controller.text = state.criticalLevel.toString();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BodyText('Initial Critical Level'),
          TextFormBox(
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            controller: _controller,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Critical level cannot be empty";
              }
              final criticalLevel = double.tryParse(value);
              if (criticalLevel == null || criticalLevel < 0) {
                return "Critical level must be a non-negative number";
              }
              return null;
            },
            onChanged: (value) {
              context
                  .read<ProductFormBloc>()
                  .add(CriticalLevelFieldChangedEvent(double.tryParse(value) ?? 0));
            },
          ),
        ].withSpacing(() => spacingBetweenNameAndForm),
      ),
    );
  }
}

class ReorderDelayFields extends StatelessWidget with ProductFormValidator {
  const ReorderDelayFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Reorder Delay'),
        Spacing.v4,
        Row(
          children: [
            Expanded(
              child: TextFormBox(
                suffix: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'days min.',
                    style: TextStyles.onSurfaceVariant.merge(TextStyles.body),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                initialValue: context.read<ProductFormBloc>().state.minReorderDelay == 0
                    ? ''
                    : context.read<ProductFormBloc>().state.minReorderDelay.toString(),
                validator: (value) => validateMinReorderDelay(
                  value,
                  context.read<ProductFormBloc>().state.maxReorderDelay,
                ),
                onChanged: (value) {
                  context
                      .read<ProductFormBloc>()
                      .add(MinReorderDelayFieldChangedEvent(int.tryParse(value) ?? 0));
                },
              ),
            ),
            Spacing.h8,
            const Text('to', style: TextStyles.body),
            Spacing.h8,
            Expanded(
                child: TextFormBox(
              suffix: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'days max.',
                  style: TextStyles.onSurfaceVariant.merge(TextStyles.body),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              initialValue: context.read<ProductFormBloc>().state.maxReorderDelay == 0
                  ? ''
                  : context.read<ProductFormBloc>().state.maxReorderDelay.toString(),
              validator: (value) => validateMaxReorderDelay(
                value,
                context.read<ProductFormBloc>().state.minReorderDelay,
              ),
              onChanged: (value) {
                context
                    .read<ProductFormBloc>()
                    .add(MaxReorderDelayFieldChangedEvent(int.tryParse(value) ?? 0));
              },
            ))
          ],
        )
      ],
    );
  }
}

class SecondaryUnitsSection extends StatelessWidget {
  const SecondaryUnitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Secondary Units', style: TextStyles.title),
            AddNewUnitButton(),
          ],
        ),
        Spacing.v8,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SecondaryUnitsLabel(),
            Flexible(child: SecondaryUnitsFormGroup()),
          ],
        ),
      ].withSpacing(() => Spacing.v4),
    );
  }
}

class SecondaryUnitsFormGroup extends StatelessWidget {
  const SecondaryUnitsFormGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final units = context.select((ProductFormBloc b) => b.state.secondaryUnits);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < units.length; ++i) ...[
          if (i > 0) Spacing.v8,
          SecondaryUnitField(index: i)
        ],
      ],
    );
  }
}

class SecondaryUnitsLabel extends StatelessWidget {
  const SecondaryUnitsLabel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: BodyText('Unit Name'),
          ),
        ),
        IgnorePointer(child: Opacity(opacity: 0.0, child: Text('per'))),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: BodyText('Equivalent'),
          ),
        ),
        Spacing.h16,
        IgnorePointer(
          child: Opacity(
            opacity: 0.0,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(FluentIcons.cancel),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AddNewUnitButton extends StatelessWidget {
  const AddNewUnitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => context.read<ProductFormBloc>().add(SecondaryUnitFieldAddedEvent()),
      child: const Padding(padding: AppPadding.a4, child: BodyText('Add New Unit')),
    );
  }
}

class SecondaryUnitField extends StatefulWidget {
  const SecondaryUnitField({super.key, required this.index});

  final int index;

  @override
  State<SecondaryUnitField> createState() => _SecondaryUnitFieldState();
}

class _SecondaryUnitFieldState extends State<SecondaryUnitField> with ProductFormValidator {
  late final TextEditingController _unitQuantityController;
  late final TextEditingController _nameController;
  late final TextEditingController _mainQuantityController;

  FormUnit? _formUnit;

  @override
  void initState() {
    super.initState();

    _unitQuantityController = TextEditingController();
    _nameController = TextEditingController();
    _mainQuantityController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final inheritedFormUnit = context.watch<ProductFormBloc>().state.secondaryUnits[widget.index];
    if (_formUnit != inheritedFormUnit) {
      _formUnit = inheritedFormUnit;

      /// When doing this as the widget is initially built, the framework throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _unitQuantityController.text = inheritedFormUnit.unitQuantity.toString();
        _nameController.text = inheritedFormUnit.name.value;
        _mainQuantityController.text = inheritedFormUnit.mainQuantity.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormBox(
                  controller: _nameController,
                  validator: (rawName) {
                    final state = context.read<ProductFormBloc>().state;
                    final secondaryUnit = state.secondaryUnits[widget.index];
                    final FormUnit(:name, :unitQuantity, :mainQuantity) = secondaryUnit;
                    assert(name.value == rawName, "Unit name must match the input.");

                    final existingNames = [
                      for (final (i, unit) in state.secondaryUnits.indexed.take(widget.index))
                        if (i != widget.index) unit.name.value,
                      state.mainUnit
                    ];

                    if (kDebugMode) {
                      printBoxed(
                        existingNames.join("\n"),
                        "Unit names tested against [${widget.index}]",
                      );
                    }

                    return validateSecondaryUnitName(
                      name: name,
                      mainQuantity: _formUnit!.mainQuantity,
                      unitQuantity: _formUnit!.unitQuantity,
                      existingNames: existingNames,
                    );
                  },
                  onChanged: (value) {
                    context //
                        .read<ProductFormBloc>()
                        .add(SecondaryUnitFieldNameChangedEvent(widget.index, name: value));
                  },
                  placeholder: "Name",
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormBox(
                  controller: _unitQuantityController,
                  validator: (rawUnitQuantity) {
                    final state = context.read<ProductFormBloc>().state;
                    final secondaryUnit = state.secondaryUnits[widget.index];
                    final FormUnit(:name, :mainQuantity, :unitQuantity) = secondaryUnit;
                    assert(
                      unitQuantity.value == rawUnitQuantity,
                      "Unit quantity must match the input.",
                    );

                    return validateSecondaryUnitQuantity(
                      secondaryName: name,
                      mainQuantity: mainQuantity,
                      unitQuantity: unitQuantity,
                    );
                  },
                  placeholder: "Quantity",
                  onChanged: (value) {
                    final state = context.read<ProductFormBloc>().state;
                    final secondaryUnit = state.secondaryUnits[widget.index];
                    final FormUnit(:mainQuantity) = secondaryUnit;
                    final event = SecondaryUnitFieldFactorChangedEvent(
                      widget.index,
                      mainQuantity: mainQuantity.value,
                      unitQuantity: value,
                    );

                    context.read<ProductFormBloc>().add(event);
                  },
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("per")),
              Expanded(
                child: TextFormBox(
                  controller: _mainQuantityController,
                  validator: (mainQuantityRaw) {
                    final state = context.read<ProductFormBloc>().state;
                    final secondaryUnit = state.secondaryUnits[widget.index];
                    final FormUnit(:name, :unitQuantity, :mainQuantity) = secondaryUnit;
                    assert(
                      mainQuantity.value == mainQuantityRaw,
                      "Main quantity must match the input.",
                    );

                    return validateMainUnitQuantity(
                      secondaryName: name,
                      mainQuantity: mainQuantity,
                      unitQuantity: unitQuantity,
                    );
                  },
                  placeholder: "Quantity",
                  onChanged: (value) {
                    final state = context.read<ProductFormBloc>().state;
                    final secondaryUnit = state.secondaryUnits[widget.index];
                    final FormUnit(:unitQuantity) = secondaryUnit;
                    final event = SecondaryUnitFieldFactorChangedEvent(
                      widget.index,
                      mainQuantity: value,
                      unitQuantity: unitQuantity.value,
                    );

                    context.read<ProductFormBloc>().add(event);
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<ProductFormBloc, ProductFormState>(
                  buildWhen: (p, c) => p.mainUnit != c.mainUnit,
                  builder: (context, state) {
                    return TextFormBox(
                      enabled: false,
                      controller: TextEditingController(text: state.mainUnit),
                      placeholder: "...",
                    );
                  },
                ),
              ),
            ].withSpacing(() => Spacing.h8),
          ),
        ),
        IconButton(
          icon: const Icon(FluentIcons.cancel),
          onPressed: () => context
              .read<ProductFormBloc>() //
              .add(SecondaryUnitFieldDeletedEvent(widget.index)),
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class QuantityUnitFields extends StatelessWidget with ProductFormValidator {
  const QuantityUnitFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Quantity on Hand'),
              TextFormBox(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                initialValue: context.read<ProductFormBloc>().state.quantity == 0
                    ? ''
                    : context.read<ProductFormBloc>().state.quantity.toString(),
                validator: validateProductQuantity,
                onChanged: (value) {
                  context
                      .read<ProductFormBloc>()
                      .add(QuantityFieldChangedEvent(double.tryParse(value) ?? 0));
                },
              ),
            ].withSpacing(() => spacingBetweenNameAndForm),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Main Unit'),
              TextFormBox(
                initialValue: context.read<ProductFormBloc>().state.mainUnit,
                validator: validateProductUnitName,
                onChanged: (value) {
                  context.read<ProductFormBloc>().add(MainUnitFieldChangedEvent(value));
                },
              ),
            ].withSpacing(() => spacingBetweenNameAndForm),
          ),
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class DeadFastStockFields extends StatelessWidget with ProductFormValidator {
  const DeadFastStockFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Dead Stock Threshold'),
              TextFormBox(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                initialValue: context.read<ProductFormBloc>().state.deadStockThreshold == 0
                    ? ''
                    : context.read<ProductFormBloc>().state.deadStockThreshold.toString(),
                validator: validateDeadStockThreshold,
                suffix: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('days', style: TextStyles.onSurfaceVariant.merge(TextStyles.body)),
                ),
                onChanged: (value) {
                  context
                      .read<ProductFormBloc>()
                      .add(DeadstockFieldChangedEvent(double.tryParse(value) ?? 0));
                },
              ),
            ].withSpacing(() => spacingBetweenNameAndForm),
          ),
        ),
        const IgnorePointer(child: Opacity(opacity: 0.0, child: Text('per'))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Moving Stock Threshold'),
              TextFormBox(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                initialValue: context.read<ProductFormBloc>().state.fastMovingThreshold == 0
                    ? ''
                    : context.read<ProductFormBloc>().state.fastMovingThreshold.toString(),
                validator: validateFastMovingThreshold,
                suffix: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('days', style: TextStyles.onSurfaceVariant.merge(TextStyles.body)),
                ),
                onChanged: (value) {
                  context
                      .read<ProductFormBloc>()
                      .add(FastMovingStockFieldChangedEvent(double.tryParse(value) ?? 0));
                },
              ),
            ].withSpacing(() => spacingBetweenNameAndForm),
          ),
        ),
      ].withSpacing(() => Spacing.h4),
    );
  }
}
