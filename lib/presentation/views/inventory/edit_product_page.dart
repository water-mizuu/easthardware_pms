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
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/inventory/product_information_form_content.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/boxed.dart';
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
            final secondaryUnits = context
                .read<UnitListBloc>()
                .state
                .units
                .where((unit) => unit.productId == product.id)
                .toList();

            final bloc = ProductFormBloc(product: product, units: secondaryUnits);

            return bloc;
          },
        ),
      ],
      child: BlocListener<ProductFormBloc, ProductFormState>(
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
                  final newCategory = Category(name: formCategory, id: stateCategories.length + 1);
                  context.read<CategoryListBloc>().add(AddCategoryEvent(newCategory));
                  return newCategory;
                },
              );

              final mappedProduct = state.toProduct().copyWith(
                    categoryId: matchedCategory.id,
                    categoryName: matchedCategory.name,
                    id: state.productId,
                  );

              context.read<UserLogListBloc>().add(AddUpdateEvent(
                    'Product #${state.productId}',
                    context.read<AuthenticationBloc>().state.user!,
                  ));

              context.read<ProductListBloc>().add(UpdateProductEvent(mappedProduct));
              final stateUnits = context.read<UnitListBloc>().state.units;
              if (kDebugMode) {
                printBoxed(stateUnits.join("\n").wrap, 'State Units');
              }
              final mappedUnits = state.secondaryUnits
                  .map((u) => u.name.isNotEmpty ? u.toUnit(state.productId!) : null)
                  .whereType<Unit>()
                  .toList();

              /// FIXME: this does not properly update the secondary units. A more advanced solution is needed to detect edits (Creation, Update, and Deletion).
              final existingUnits = mappedUnits.where(stateUnits.contains).toList();
              final newUnits = List<Unit>.from(mappedUnits);
              mappedUnits.retainWhere(stateUnits.contains);

              for (final unit in existingUnits) {
                context.read<UnitListBloc>().add(UpdateUnitEvent(unit));
              }
              for (final unit in newUnits) {
                context.read<UnitListBloc>().add(AddUnitEvent(unit));
              }

              context.read<ProductFormBloc>().add(FormSubmittedEvent());
              break;
            case FormStatus.submitted:
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  context.read<ProductFormBloc>().add(FormResetEvent());
                  context.navigate(AppRoutes.inventoryPage);
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
      ),
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
          onPressed: () => context.navigate(AppRoutes.inventoryPage),
        ),
        const DisplayText('Edit Product'),
        const Spacer(flex: 1),
        TextButton('Archive Product', onPressed: () {
          // Set Status to Inactive
          final previous = context.read<ProductFormBloc>().state.archiveStatus;
          final current = previous == 0 ? 1 : 0;
          context.read<ProductFormBloc>().add(ProductStatusChangedEvent(current));

          // Update Product
          final productId = context.read<ProductFormBloc>().state.productId!;
          final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
          context.read<UserLogListBloc>().add(AddArchiveEvent(
                'Product #${context.read<ProductFormBloc>().state.productId}',
                context.read<AuthenticationBloc>().state.user!,
              ));
          context.read<ProductFormBloc>().add(FormButtonPressedEvent(
                productId: productId,
                creatorId: creatorId,
              ));
        }),
        TextButtonFilled('Update Product', onPressed: () {
          // Added 1 because SQLite has one-based indexing
          // Take actual productId
          // Add onUpdate Event
          final productId = context.read<ProductFormBloc>().state.productId!;
          final creatorId = context.read<ProductFormBloc>().state.creatorId!;
          context.read<ProductFormBloc>().add(FormButtonPressedEvent(
                productId: productId,
                creatorId: creatorId,
              ));
        })
      ].withSpacing(() => Spacing.h16),
    );
  }
}
