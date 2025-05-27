import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/inventory/category_form/category_form_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PageHeader(),
          PageActions(),
          PageTable(),
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }
}

class PageTable extends StatelessWidget {
  const PageTable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListBloc, ProductListState>(
      builder: (context, state) {
        final activeProducts = context
            .read<ProductListBloc>()
            .state
            .allProducts
            .where((product) => product.archiveStatus == 0);
        return BlocBuilder<CategoryListBloc, CategoryListState>(
          builder: (context, state) {
            final categories = context.read<CategoryListBloc>().state.categories;
            final categoryRowMap = <int, int>{};

            for (final p in activeProducts) {
              categoryRowMap.update(p.categoryId!, (count) => count + 1, ifAbsent: () => 1);
            }

            return Expanded(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text("Category Name")),
                    DataColumn(label: Text("Products")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: categories
                      .map(
                        (category) => DataRowMapper.mapCategoryToRow(
                          category,
                          categoryRowMap[category.id] ?? 0,
                          () {
                            showContentDialog(context, category);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
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
          onPressed: () => context.read<NavigationBloc>().add(
                NavigationIndexChanged(
                    index: RouteIndexMapper.getIndexFromRoute(AppRoutes.inventoryPage)!),
              ),
        ),
        const HeadingText('Manage Categories'),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SubheadingText('List of Categories'),
        const Expanded(child: TextBox(placeholder: 'Search')),
        const Spacer(flex: 2),
        TextButtonFilled('Add Category', onPressed: () => showContentDialog(context))
      ].withSpacing(() => Spacing.h8),
    );
  }
}

Future<void> showContentDialog(BuildContext context, [Category? category]) async {
  await showDialog(
      context: context,
      builder: (context) {
        final bloc = context.read<CategoryListBloc>();
        final existingNames = bloc.state.categories.map((category) => category.name).toList();
        final isAdding = category == null;
        return BlocProvider(
          create: (context) => CategoryFormCubit(),
          child: Builder(builder: (context) {
            final formKey = context.read<CategoryFormCubit>().formKey;
            return BlocListener<CategoryFormCubit, CategoryFormState>(
              listener: (context, state) {
                switch (state.status) {
                  case FormStatus.submitting:
                    if (isAdding) {
                      bloc.add(AddCategoryEvent(Category(name: state.name!)));
                    } else {
                      bloc.add(UpdateCategoryEvent(category.copyWith(name: state.name!)));
                    }
                    context.read<CategoryFormCubit>().onSubmit();
                    break;
                  case FormStatus.submitted:
                    if (context.mounted) {
                      context.pop();
                      context.read<CategoryFormCubit>().onFormReset();
                    }
                  default:
                    break;
                }
              },
              child: ContentDialog(
                title: SubheadingText(isAdding ? 'Create a new Category' : 'Edit ${category.name}'),
                content: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BodyText('Name'),
                      TextFormBox(
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name cannot be empty';
                          }
                          if (existingNames.contains(value.trim()) && isAdding) {
                            return 'Category already exist';
                          }
                          return null;
                        },
                        initialValue: isAdding ? '' : category.name,
                        onChanged: context.read<CategoryFormCubit>().onFormNameChanged,
                      ),
                    ].withSpacing(() => Spacing.v12),
                  ),
                ),
                actions: [
                  TextButton('Cancel', onPressed: context.pop),
                  TextButtonFilled('Save Category',
                      onPressed: context.read<CategoryFormCubit>().onButtonPressed)
                ],
              ),
            );
          }),
        );
      });
}
