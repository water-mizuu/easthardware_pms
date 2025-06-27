import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';

import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/inventory/category_display/category_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/inventory/category_form/category_form_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/inventory/category_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  @override
  initState() {
    super.initState();
    final products = context.read<ProductListBloc>().state.allProducts;
    context.read<CategoryDisplayCubit>().updateCategories(
          context
              .read<CategoryListBloc>()
              .state
              .categories
              .map(
                (category) => DisplayCategory.fromCategory(category,
                    productCount: products
                        .where((product) =>
                            product.categoryId == category.id && product.archiveStatus == 0)
                        .length),
              )
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryListBloc, CategoryListState>(
      listenWhen: (previous, current) => previous.categories != current.categories,
      listener: (context, state) {
        context.read<CategoryDisplayCubit>().updateCategories(
              state.categories
                  .map(
                    (category) => DisplayCategory.fromCategory(category),
                  )
                  .toList(),
            );
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PageHeader(),
            PageActions(),
            CategoriesDataTable(),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class CategoriesDataTable extends StatelessWidget {
  const CategoriesDataTable({
    super.key,
  });

  int? _getSortColumnIndex(CategoryDisplaySortBy sortBy) {
    switch (sortBy) {
      case CategoryDisplaySortBy.nameAscending:
      case CategoryDisplaySortBy.nameDescending:
        return 0; // Index of the Name column
      case CategoryDisplaySortBy.productCountAscending:
      case CategoryDisplaySortBy.productCountDescending:
        return 1; // Index of the Products column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListBloc, ProductListState>(
      builder: (context, productState) {
        return BlocBuilder<CategoryDisplayCubit, CategoryDisplayState>(
          builder: (context, state) {
            final categories = state.allCategories;

            return Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                child: categories == null || categories.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Center(
                          child: BodyText('No categories available'),
                        ),
                      )
                    : TableThemeData(
                        child: PaginatedDataTable(
                          showFirstLastButtons: true,
                          showCheckboxColumn: false,
                          horizontalMargin: 20,
                          columnSpacing: 16,
                          sortColumnIndex: _getSortColumnIndex(state.sortBy),
                          sortAscending: state.sortAscending,
                          checkboxHorizontalMargin: 0,
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 300),
                                  child: Row(
                                    children: [
                                      const Text('Category Name', style: TextStyles.strong),
                                      if (_getSortColumnIndex(state.sortBy) != 0) ...[
                                        const Spacer(),
                                        const Icon(
                                          FluentIcons.scroll_up_down,
                                          size: 12,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              onSort: (_, __) {
                                if (state.sortBy == CategoryDisplaySortBy.nameAscending ||
                                    state.sortBy == CategoryDisplaySortBy.nameDescending) {
                                  context.read<CategoryDisplayCubit>().sort(state.sortBy);
                                } else {
                                  context
                                      .read<CategoryDisplayCubit>()
                                      .sort(CategoryDisplaySortBy.nameAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 300),
                                  child: Row(
                                    children: [
                                      const Text('No. of Products', style: TextStyles.strong),
                                      if (_getSortColumnIndex(state.sortBy) != 1) ...[
                                        const Spacer(),
                                        const Icon(
                                          FluentIcons.scroll_up_down,
                                          size: 12,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              onSort: (_, __) {
                                if (state.sortBy == CategoryDisplaySortBy.productCountAscending ||
                                    state.sortBy == CategoryDisplaySortBy.productCountDescending) {
                                  context.read<CategoryDisplayCubit>().sort(state.sortBy);
                                } else {
                                  context
                                      .read<CategoryDisplayCubit>()
                                      .sort(CategoryDisplaySortBy.productCountAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 40),
                                child: const Text(''),
                              ),
                            ),
                          ],
                          source: CategoryDataSource(
                            context: context,
                            categories: categories,
                          ),
                        ),
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
            onPressed: () => context.navigate(AppRoutes.admin.inventory)),
        const Text('Manage Categories', style: TextStyles.display),
        const Spacer(),
        TextButtonFilled('Add Category', onPressed: () => unawaited(showContentDialog(context)))
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    String? validator(String query) {
      final products = context.read<ProductListBloc>().state.allProducts;
      final categories = context
          .read<CategoryListBloc>()
          .state
          .categories
          .map(
            (category) => DisplayCategory.fromCategory(category,
                productCount: products
                    .where((product) =>
                        product.categoryId == category.id && product.archiveStatus == 0)
                    .length),
          )
          .toList();
      if (query.isEmpty) {
        context.read<CategoryDisplayCubit>().updateCategories(categories);
      } else {
        final filteredCategories = categories
            .where((category) => category.category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        context.read<CategoryDisplayCubit>().updateCategories(
              filteredCategories
                  .map((category) => DisplayCategory.fromCategory(category.category))
                  .toList(),
            );
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('List of Categories', style: TextStyles.subtitle),
        Spacing.v12,
        Row(
          children: [
            Expanded(child: TextBox(placeholder: 'Search by category name', onChanged: validator)),
            const Spacer(flex: 2),
          ].withSpacing(() => Spacing.h8),
        ),
      ],
    );
  }
}

Future<void> showContentDialog(BuildContext context, [Category? category]) async {
  await showSingleDialog(
    barrierDismissible: true,
    (context) {
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
                    final products = context.read<ProductListBloc>().state.allProducts;
                    // After a category is added or updated, refresh the CategoryListCubit
                    final parentContext = Navigator.of(context).context;
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (parentContext.mounted) {
                        final updatedCategories =
                            parentContext.read<CategoryListBloc>().state.categories;
                        parentContext.read<CategoryDisplayCubit>().updateCategories(
                              updatedCategories
                                  .map(
                                    (category) => DisplayCategory.fromCategory(category,
                                        productCount: products
                                            .where((product) =>
                                                product.categoryId == category.id &&
                                                product.archiveStatus == 0)
                                            .length),
                                  )
                                  .toList(),
                            );
                      }
                    });
                    context.pop();
                  }
                default:
                  break;
              }
            },
            child: ContentDialog(
              title: Text(
                isAdding ? 'Create a new Category' : 'Edit ${category.name}',
                style: TextStyles.title,
              ),
              content: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Name', style: TextStyles.body),
                    TextFormBox(
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        if (existingNames.contains(value.trim()) && isAdding) {
                          return 'Category already exists';
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
    },
  );
}
