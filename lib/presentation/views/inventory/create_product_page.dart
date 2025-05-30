import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scroll_animator/scroll_animator.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  late final ProductFormBloc productFormBloc;
  late final AnimatedScrollController scrollController;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider.value(value: productFormBloc),
    ];
  }

  List<BlocListener> get listeners {
    void handleFormSubmit(BuildContext context, ProductFormState state) {
      // Handle Category Search and Creation
      final formCategory = state.categoryName;
      final stateCategories = context.read<CategoryListBloc>().state.categories;
      final matchedCategory = stateCategories.firstWhere(
        (category) => category.name == formCategory,
        orElse: () {
          /// If no match found, create a new category.
          final newCategory = Category(name: formCategory, id: stateCategories.length + 1);
          context.read<CategoryListBloc>().add(AddCategoryEvent(newCategory));

          return newCategory;
        },
      );

      final createdProduct = state.toProduct().copyWith(
            categoryId: matchedCategory.id,
            categoryName: matchedCategory.name,
            id: state.productId,
          );

      context.read<ProductListBloc>().add(AddProductEvent(createdProduct));

      final addCreateEvent = AddCreateEvent(
        'Product #${state.productId}',
        context.read<AuthenticationBloc>().state.user!,
      );
      context.read<UserLogListBloc>().add(addCreateEvent);

      final mappedUnits = state.secondaryUnits
          .where((unit) => unit.name.isNotEmpty && unit.factor.isNotEmpty)
          .map((unit) => unit.toUnit(state.productId!));

      for (final unit in mappedUnits) {
        context.read<UnitListBloc>().add(AddUnitEvent(unit));
      }

      /// Let the form know that the submission is complete,
      ///   and we reset the form state.
      context.read<ProductFormBloc>().add(FormSubmittedEvent());
    }

    return [
      BlocListener<ProductFormBloc, ProductFormState>(
        bloc: productFormBloc,
        listener: (context, state) {
          switch (state.formStatus) {
            case FormStatus.submitting:
              handleFormSubmit(context, state);
              break;
            case FormStatus.submitted:
              context.read<ProductFormBloc>().add(FormResetEvent());

              /// Navigate to the inventory page after successful submission.
              final index = RouteIndexMapper.getIndexFromRoute(AppRoutes.inventoryPage);
              context.read<NavigationBloc>().add(NavigationIndexChanged(index: index!));
              break;
            default:
              break;
          }
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    productFormBloc = ProductFormBloc();
    scrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    productFormBloc.close();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocListener(
        listeners: listeners,
        child: buildWidget(context),
      ),
    );
  }

  Widget buildWidget(BuildContext context) {
    return FocusScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: AppPadding.panePadding.top,
              left: AppPadding.panePadding.left,
              right: AppPadding.panePadding.right,
            ),
            child: const PageHeader(),
          ),
          Expanded(
            child: Form(
              key: productFormBloc.formKey,
              child: LayoutMode.builder(
                builder: (context, layoutMode) {
                  switch (layoutMode) {
                    case LayoutMode.wide:
                      return Padding(
                        padding: EdgeInsets.only(
                          left: AppPadding.panePadding.left,
                          right: AppPadding.panePadding.right,
                          bottom: AppPadding.panePadding.bottom,
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: LeftColumn()),
                            Spacing.h16,
                            Expanded(child: RightColumn()),
                          ],
                        ),
                      );
                    case LayoutMode.constrained:
                    case LayoutMode.compact:
                      return SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: AppPadding.panePadding.left,
                            right: AppPadding.panePadding.right,
                            bottom: AppPadding.panePadding.bottom,
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LeftColumn(),
                              Spacing.v16,
                              RightColumn(),
                            ],
                          ),
                        ),
                      );
                  }
                },
              ),
            ),
          ),
        ].withSpacing(() => Spacing.v16),
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
    return Container(
      padding: AppPadding.a16,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubheadingText('Sale Information'),
          Spacing.v16,
          const BodyText('Sale Price'),
          Spacing.v4,
          TextFormBox(
            validator: validateProductPrice,
            onChanged: (value) {
              context.read<ProductFormBloc>().add(PriceFieldChangedEvent(value));
            },
          ),
        ],
      ),
    );
  }
}

class OrderInformationSection extends StatelessWidget with ProductFormValidator {
  const OrderInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.a16,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubheadingText('Order Information'),
          Spacing.v16,
          const BodyText('Order Cost'),
          Spacing.v4,
          TextFormBox(
            validator: validateProductCost,
            onChanged: (value) {
              context.read<ProductFormBloc>().add(CostFieldChangedEvent(value));
            },
          ),
        ],
      ),
    );
  }
}

class BasicInformationSection extends StatelessWidget with ProductFormValidator {
  const BasicInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.a16,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubheadingText('Basic Information'),
          Spacing.v16,
          const BodyText('Product Name'),
          Spacing.v4,
          TextFormBox(
            autofocus: true,
            validator: validateProductName,
            onChanged: (value) {
              context.read<ProductFormBloc>().add(NameFieldChangedEvent(value));
            },
          ),
          Spacing.v8,
          const BodyText('Stock Keeping Unit (SKU)'),
          Spacing.v4,
          TextFormBox(
            placeholder: context.read<ProductFormBloc>().state.sku,
            onChanged: (value) {
              context.read<ProductFormBloc>().add(SkuFieldChangedEvent(value));
            },
          ),
          Spacing.v8,
          const BodyText('Category'),
          Spacing.v4,
          BlocBuilder<CategoryListBloc, CategoryListState>(
            builder: (context, state) {
              return AutoSuggestBox.form(
                validator: validateProductCategory,
                items: state.categories
                    .map((category) => AutoSuggestBoxItem(value: category, label: category.name))
                    .toList(),
                onChanged: (value, reason) {
                  context.read<ProductFormBloc>().add(CategoryFieldChangedEvent(value));
                },
                onSelected: (value) {
                  context.read<ProductFormBloc>().add(CategoryIdChangedEvent(value.value!.id!));
                },
              );
            },
          ),
          Spacing.v8,
          const BodyText('Description'),
          Spacing.v4,
          TextBox(
            minLines: 2,
            maxLines: 2,
            onChanged: (value) {
              context.read<ProductFormBloc>().add(DescriptionFieldChangedEvent(value));
            },
          ),
          Spacing.v8,
          const QuantityUnitFields(),
          Spacing.v8,
          const BodyText('Critical Level'),
          Spacing.v4,
          const CriticalLevelField(),
          Spacing.v8,
          const DeadFastStockFields(),
        ],
      ),
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
    _controller = TextEditingController(text: bloc.state.criticalLevel);
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
        _controller.text = state.criticalLevel;
      },
      child: TextFormBox(
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
          context.read<ProductFormBloc>().add(CriticalLevelFieldChangedEvent(value));
        },
      ),
    );
  }
}

class SecondaryUnitsSection extends StatelessWidget {
  const SecondaryUnitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.a16,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SubheadingText('Secondary Units'),
              AddNewUnitButton(),
            ],
          ),
          Spacing.v12,
          BlocBuilder<ProductFormBloc, ProductFormState>(
            builder: (context, state) {
              final units = state.secondaryUnits;
              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => Spacing.v8,
                  itemCount: units.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SecondaryUnitField(index: index);
                  },
                ),
              );
            },
          ),
        ].withSpacing(() => Spacing.v4),
      ),
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

class SecondaryUnitField extends StatelessWidget with ProductFormValidator {
  const SecondaryUnitField({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFormBloc>();
    final state = bloc.state;
    final existingNames = [...state.secondaryUnits.map((u) => u.name), state.mainUnit]
      ..removeAt(index);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index == 0) const BodyText('Unit Name'),
              if (index == 0) Spacing.v4,
              TextFormBox(
                validator: (value) {
                  return validateSecondaryUnitName(name: value, existingNames: existingNames);
                },
                onChanged: (value) {
                  bloc.add(SecondaryUnitFieldNameChangedEvent(value, index));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index == 0) const BodyText('Equivalent'),
              if (index == 0) Spacing.v4,
              TextFormBox(
                validator: (value) {
                  final factor = value ?? '';
                  final name = context.read<ProductFormBloc>().state.secondaryUnits[index].name;
                  return validateSecondaryUnitFactor(name: name, factor: factor);
                },
                onChanged: (value) {
                  bloc.add(SecondaryUnitFieldFactorChangedEvent(value, index));
                },
              ),
            ],
          ),
        ),
        Column(
          children: [
            const Text(''),
            IconButton(
              icon: const Icon(FluentIcons.cancel),
              onPressed: () => bloc.add(SecondaryUnitFieldDeletedEvent(index)),
            ),
          ],
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Quantity on Hand'),
              TextFormBox(
                validator: validateProductQuantity,
                onChanged: (value) {
                  context.read<ProductFormBloc>().add(QuantityFieldChangedEvent(value));
                },
              ),
            ].withSpacing(() => Spacing.v12),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Main Unit'),
              TextFormBox(
                validator: validateProductUnitName,
                onChanged: (value) {
                  context.read<ProductFormBloc>().add(MainUnitFieldChangedEvent(value));
                },
              ),
            ].withSpacing(() => Spacing.v12),
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Dead Stock Threshold'),
              TextFormBox(
                placeholder: context.read<ProductFormBloc>().state.deadStockThreshold,
                validator: validateDeadStockThreshold,
                suffix: const Padding(padding: AppPadding.a4, child: GrayText('Days')),
                onChanged: (value) {
                  context.read<ProductFormBloc>().add((DeadstockFieldChangedEvent(value)));
                },
              ),
            ].withSpacing(() => Spacing.v12),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Moving Stock Threshold'),
              TextFormBox(
                placeholder: context.read<ProductFormBloc>().state.fastMovingThreshold,
                validator: validateFastMovingThreshold,
                suffix: const Padding(padding: AppPadding.a4, child: GrayText('Days')),
                onChanged: (value) {
                  context.read<ProductFormBloc>().add(FastMovingStockFieldChangedEvent(value));
                },
              ),
            ].withSpacing(() => Spacing.v12),
          ),
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.read<NavigationBloc>().add(
                NavigationIndexChanged(
                  index: RouteIndexMapper.getIndexFromRoute(AppRoutes.inventoryPage)!,
                ),
              ),
        ),
        const DisplayText('Add Product'),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save Product',
          onPressed: () {
            // Added 1 because SQLite has one-based indexing
            final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
            final productId = 1 + context.read<ProductListBloc>().state.allProducts.length;
            context.read<ProductFormBloc>().add(
                  FormButtonPressedEvent(productId: productId, creatorId: creatorId),
                );
          },
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}
