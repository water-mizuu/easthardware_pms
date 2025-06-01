import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/inventory/product_information_form_content.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class CreateProductPage extends StatelessWidget {
  const CreateProductPage({super.key});

  void _handleFormSubmit(BuildContext context, ProductFormState state) {
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
        .where((formUnit) => formUnit.name.isNotEmpty)
        .map((formUnit) => formUnit.toUnit(state.productId!));

    for (final unit in mappedUnits) {
      context.read<UnitListBloc>().add(AddUnitEvent(unit));
    }

    /// Let the form know that the submission is complete,
    ///   and we reset the form state.
    context.read<ProductFormBloc>().add(FormSubmittedEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [BlocProvider(create: (_) => ProductFormBloc())],
      builder: (context, child) {
        return BlocListener<ProductFormBloc, ProductFormState>(
          listener: (context, state) {
            switch (state.formStatus) {
              case FormStatus.submitting:
                _handleFormSubmit(context, state);
                break;
              case FormStatus.submitted:

                /// Reset the form
                context.read<ProductFormBloc>().add(FormResetEvent());

                /// Navigate to the inventory page after successful submission.
                final index =
                    RouteIndexMapper.of(context).getIndexFromRoute(AppRoutes.inventoryPage);
                context.read<NavigationBloc>().goIndex(index!);
                break;
              default:
                break;
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppPadding.panePadding.copyWith(bottom: 0.0),
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
          onPressed: () => context
              .read<NavigationBloc>()
              .goIndex(RouteIndexMapper.of(context).getIndexFromRoute(AppRoutes.inventoryPage)!),
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
