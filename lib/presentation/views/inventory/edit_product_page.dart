import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/inventory/product_information_form_content.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class EditProductPage extends StatelessWidget {
  const EditProductPage({required this.product, super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final unitState = context.read<UnitListBloc>().state;
            final secondaryUnits = unitState.units //
                .where((u) => u.productId == product.id)
                .toList();

            printBoxed(product.toMap(), 'Editing Product');
            return ProductFormBloc.fromProduct(product, secondaryUnits);
          },
        ),
      ],
      builder: (context, _) {
        return MultiBlocListener(
          listeners: [
            BlocListener<UnitListBloc, UnitListState>(
              listenWhen: (p, c) => p.units != c.units,
              listener: (context, state) {
                assert(product.id != null, 'Product ID must not be null');

                final productFormBloc = context.read<ProductFormBloc>();
                final allSecondaryUnits = state.units;
                final unitsOfThisProduct = allSecondaryUnits //
                    .where((u) => u.productId == product.id)
                    .toList();
                if (kDebugMode) {
                  printBoxed(
                    unitsOfThisProduct.map((u) => u.toMap()).join("\n").wrap,
                    'Units of Product #${product.id}',
                  );
                }

                productFormBloc.add(ProductLoadedEvent(product, unitsOfThisProduct));
              },
            ),
            BlocListener<ProductFormBloc, ProductFormState>(
              listenWhen: (p, c) => p.formStatus != c.formStatus,
              listener: (context, state) {
                switch (state.formStatus) {
                  case FormStatus.initial:
                    break;
                  case FormStatus.submitting:
                    // Handle Category Search and Creation
                    final formCategory = state.categoryName;
                    final stateCategories = context.read<CategoryListBloc>().state.categories;

                    final matchedCategory = stateCategories.firstWhere(
                      (category) => category.name == formCategory,
                      orElse: () {
                        final newCategory = Category(
                          name: formCategory,
                          id: stateCategories.length + 1,
                        );
                        context.read<CategoryListBloc>().add(AddCategoryEvent(newCategory));
                        return newCategory;
                      },
                    );

                    final mappedProduct = state //
                        .toProduct()
                        .copyWith(
                          categoryId: matchedCategory.id,
                          categoryName: matchedCategory.name,
                          id: state.productId,
                        );

                    final user = context.read<AuthenticationBloc>().state.user!;
                    context //
                        .read<UserLogListBloc>()
                        .add(AddUpdateEvent('Product #${state.productId}', user));

                    context //
                        .read<ProductListBloc>()
                        .add(UpdateProductEvent(mappedProduct));

                    /// UPDATING UNITS IN DATABASE.

                    final unitsExistingInDb = context.read<UnitListBloc>().state.units;
                    if (kDebugMode) {
                      printBoxed(unitsExistingInDb.join("\n").wrap, 'State Units');
                    }

                    final unitsExistingInDbForProduct = unitsExistingInDb //
                        .where((u) => u.productId == state.productId)
                        .toList();

                    /// Convert each of the form units into actual [Unit] objects.
                    final mappedUnitsInForm = state.secondaryUnits
                        .map((u) => u.name.value.isNotEmpty ? u.toUnit(state.productId!) : null)
                        .whereType<Unit>()
                        .toList();

                    assert(
                      mappedUnitsInForm.every((u) => u.productId == state.productId),
                      'All units in the form should have the same product ID as the current product.',
                    );

                    /// The units are added when they don't match any unit existing in the database
                    ///   for the same product.
                    final createdUnits = mappedUnitsInForm //
                        /// Safety check
                        .where((u) => u.productId == state.productId)

                        /// A unit is only new for a product [p] if it does not match
                        ///   with a unit in the database with the same name .
                        .where((u) => u.id == null)
                        .toList();

                    assert(
                      createdUnits.every((u) => u.id == null),
                      'All added units should have a null ID.',
                    );

                    for (final unit in createdUnits) {
                      context.read<UnitListBloc>().add(AddUnitEvent(unit));
                    }

                    /// Units are modified when they DO match a unit in the database.
                    final modifiedExistingUnits = mappedUnitsInForm

                        /// Safety check
                        .where((u) => u.productId == state.productId)

                        /// A unit is modified if it matches a unit in the database
                        ///   with the same unit ID.
                        .where((u) => unitsExistingInDbForProduct.any((m) => m.id == u.id))
                        .toList();

                    assert(
                      modifiedExistingUnits.every((u) => u.id != null),
                      'All existing units should have an ID assigned.',
                    );

                    /// Apply the changes to the database.
                    for (final unit in modifiedExistingUnits) {
                      context.read<UnitListBloc>().add(UpdateUnitEvent(unit));
                    }

                    /// Units are removed when they exist in the database but not in the form.
                    /// We assert that all removed units have the same product
                    ///   ID as the current product.
                    final removedUnits = unitsExistingInDbForProduct //
                        .where((m) => !mappedUnitsInForm.any((u) => m.id == u.id));

                    assert(
                      removedUnits.every((u) => u.productId == state.productId),
                      'All removed units should have the same product ID as the current product.',
                    );
                    assert(
                      removedUnits.every((u) => u.id != null),
                      'All removed units should have a non-null ID.',
                    );

                    /// Apply the changes to the database.
                    for (final unit in removedUnits) {
                      if (unit.id case final id?) {
                        context.read<UnitListBloc>().add(DeleteUnitEvent(id));
                      }
                    }

                    context.read<ProductFormBloc>().add(FormSubmittedEvent());
                    break;
                  case FormStatus.submitted:
                    Future.delayed(Duration.zero, () {
                      if (context.mounted) {
                        context.read<ProductFormBloc>().add(FormResetEvent());
                        context.navigate(AppRoutes.admin.inventory);
                      }
                    });
                  case FormStatus.error:
                    if (kDebugMode) {
                      print("Error");
                    }
                    break;
                  default:
                    break;
                }
              },
            ),
          ],
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
              const Expanded(child: ProductInformationFormContent()),
            ].withSpacing(() => Spacing.v16),
          ),
        );
      },
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
          onPressed: () => context.navigate(AppRoutes.admin.inventory),
        ),
        const DisplayText('Edit Product'),
        const Spacer(flex: 1),
        TextButton('Archive Product', onPressed: () {
          // Set Status to Inactive
          final previous = context.read<ProductFormBloc>().state.archivedStatus;
          final current = previous == 0 ? 1 : 0;
          context.read<ProductFormBloc>().add(ProductStatusChangedEvent(current));
          if (kDebugMode) {
            printBoxed(
              'Product Status changed from $previous to $current',
              'EditProductPage',
            );
          }

          // Update Product
          final productId = context.read<ProductFormBloc>().state.productId!;
          final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
          context
            ..read<UserLogListBloc>().add(AddArchiveEvent(
              'Product #${context.read<ProductFormBloc>().state.productId}',
              context.read<AuthenticationBloc>().state.user!,
            ))
            ..read<ProductFormBloc>().add(FormButtonPressedEvent(
              productId: productId,
              creatorId: creatorId,
            ));
        }),
        TextButtonFilled('Update Product', onPressed: () {
          // Added 1 because SQLite has one-based indexing
          // Take actual productId
          // Add onUpdate Event
          final ProductFormState(:productId!, :creatorId!) = context.read<ProductFormBloc>().state;
          if (kDebugMode) {
            printBoxed(
              'Product Status changed from $productId to $creatorId',
              'EditProductPage',
            );
          }
          context //
              .read<ProductFormBloc>()
              .add(FormButtonPressedEvent(
                productId: productId,
                creatorId: creatorId,
              ));
        })
      ].withSpacing(() => Spacing.h16),
    );
  }
}
