import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/'
    'category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/'
    'inventory/product_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show DataColumn, DataRow, DataTableSource, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryPanePage extends StatefulWidget {
  const InventoryPanePage({super.key});

  @override
  State<InventoryPanePage> createState() => _InventoryPanePageState();
}

class _InventoryPanePageState extends State<InventoryPanePage> {
  @override
  void initState() {
    super.initState();

    context //
        .read<InventoryDisplayBloc>()
        .add(InventoryDisplayItemsUpdatedEvent(
          WeakReference(context.read<ProductListBloc>().state.allProducts),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductListBloc, ProductListState>(
      listenWhen: (p, c) => p.allProducts != c.allProducts,
      listener: (context, state) {
        context
            .read<InventoryDisplayBloc>()
            .add(InventoryDisplayItemsUpdatedEvent(WeakReference(state.allProducts)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: AppPadding.panePadding,
            child: PageHeader(),
          ),
          Spacing.v4,
          Expanded(
            child: AnimatedSingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.panePadding.horizontal / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _InventorySummary(),
                    ProductListSection(),
                  ].withSpacing(() => Spacing.v16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final access = context.select((AuthenticationBloc b) => b.state.user?.accessLevel);
    if (access != AccessLevel.administrator) {
      return const HeadingText('Products');
    }

    return Row(
      children: [
        const HeadingText('Products'),
        const Spacer(flex: 1),
        TextButton('Manage Categories', onPressed: () {
          context.navigate(AppRoutes.admin.categories);
        }),
        TextButtonFilled('New Product', onPressed: () {
          context.navigate(AppRoutes.admin.createProduct);
        }),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductListBloc>().state;
    final activeCount = state.allProducts.where((product) => product.archiveStatus == 0).length;
    final lowStockCount = state.lowStockProducts.length;
    final fastMovingCount = state.fastMovingProducts.length;
    final deadCount = state.deadStockProducts.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Inventory Summary'),
        LayoutMode.builder((context, layoutMode, keys) {
          switch (layoutMode) {
            case LayoutMode.wide:
              return IntrinsicHeight(
                child: Row(
                  children: [
                    ActiveCountCard(
                      value: activeCount.toString(),
                      key: keys['activeCount'],
                    ),
                    LowStockCountCard(
                      value: lowStockCount.toString(),
                      key: keys['lowStockCount'],
                    ),
                    HangingCountCard(
                      value: deadCount.toString(),
                      key: keys['deadCount'],
                    ),
                    FastMovingCountCard(
                      value: fastMovingCount.toString(),
                      key: keys['fastMovingCount'],
                    ),
                  ].withSpacing(() => Spacing.h16),
                ),
              );
            case LayoutMode.constrained:
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        ActiveCountCard(
                          value: activeCount.toString(),
                          key: keys['activeCount'],
                        ),
                        LowStockCountCard(
                          value: lowStockCount.toString(),
                          key: keys['lowStockCount'],
                        ),
                      ].withSpacing(() => Spacing.h8),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        HangingCountCard(
                          value: deadCount.toString(),
                          key: keys['deadCount'],
                        ),
                        FastMovingCountCard(
                          value: fastMovingCount.toString(),
                          key: keys['fastMovingCount'],
                        ),
                      ].withSpacing(() => Spacing.h8),
                    ),
                  ),
                ].withSpacing(() => Spacing.v8),
              );
            case LayoutMode.compact:
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActiveCountCard(
                    value: activeCount.toString(),
                    isExpanded: false,
                    key: keys['activeCount'],
                  ),
                  LowStockCountCard(
                    value: lowStockCount.toString(),
                    isExpanded: false,
                    key: keys['lowStockCount'],
                  ),
                  HangingCountCard(
                    value: deadCount.toString(),
                    isExpanded: false,
                    key: keys['deadCount'],
                  ),
                  FastMovingCountCard(
                    value: fastMovingCount.toString(),
                    isExpanded: false,
                    key: keys['fastMovingCount'],
                  ),
                ].withSpacing(() => Spacing.v8),
              );
          }
        }),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ActiveCountCard extends KPICard {
  const ActiveCountCard({super.key, required super.value, super.isExpanded})
      : super('Active Products', icon: const Icon(FluentIcons.product));
}

class LowStockCountCard extends KPICard {
  const LowStockCountCard({super.key, required super.value, super.isExpanded})
      : super('Low Stock Products', icon: const Icon(FluentIcons.product_warning));
}

class HangingCountCard extends KPICard {
  const HangingCountCard({super.key, required super.value, super.isExpanded})
      : super('Hanging Products', icon: const Icon(FluentIcons.market_down));
}

class FastMovingCountCard extends KPICard {
  const FastMovingCountCard({super.key, required super.value, super.isExpanded})
      : super('Fast Moving Products', icon: const Icon(FluentIcons.market));
}

class SearchRow extends StatelessWidget {
  const SearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextBox(
            placeholder: "Search",
            onChanged: (query) {
              context
                  .read<InventoryDisplayBloc>()
                  .add(InventoryDisplaySearchEvent(query.trim().toLowerCase()));
            },
          ),
        ),
        const CategoryButton(),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h8),
    );
  }
}

class CategoryButton extends StatefulWidget {
  const CategoryButton({super.key});

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  double? width;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      if (context.mounted) {
        setState(() {
          width = context.size?.width;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.select((CategoryListBloc b) => b.state.categories);
    final selectedCategory = context.select((InventoryDisplayBloc b) => b.state.category);

    return DropDownButton(
      title: Padding(
        padding: AppPadding.a4,
        child: selectedCategory != null
            ? ButtonText(selectedCategory.name, overflow: TextOverflow.fade)
            : const ButtonText('Category'),
      ),
      items: [
        MenuFlyoutItem(
          text: const BodyText('No Categories'),
          onPressed: () {
            context //
                .read<InventoryDisplayBloc>()
                .add(const InventoryDisplayCategoryEvent(null));
          },
        ),
        for (final category in categories)
          MenuFlyoutItem(
            text: BodyText(category.name),
            onPressed: () {
              context //
                  .read<InventoryDisplayBloc>()
                  .add(InventoryDisplayCategoryEvent(category));
            },
          ),
      ],
    );
  }
}

class ProductListSection extends StatelessWidget {
  const ProductListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('List of Products'),
        const SearchRow(),
        const ProductsDataTable(),

        /// Blank space to allow space for scrolling past the table.
        Spacing.v12,
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ProductsDataTable extends StatelessWidget {
  const ProductsDataTable({super.key});

  int? _getSortColumnIndex(InventoryDisplaySortBy sortBy) {
    switch (sortBy) {
      case InventoryDisplaySortBy.nameAscending:
      case InventoryDisplaySortBy.nameDescending:
        return 0; // Index of the Name column

      case InventoryDisplaySortBy.categoryAscending:
      case InventoryDisplaySortBy.categoryDescending:
        return 1; // Index of the Category column

      case InventoryDisplaySortBy.priceAscending:
      case InventoryDisplaySortBy.priceDescending:
        return 2; // Index of the Sale Price column

      case InventoryDisplaySortBy.stockAscending:
      case InventoryDisplaySortBy.stockDescending:
        return 3; // Index of the Quantity column

      case InventoryDisplaySortBy.urgencyAscending:
        return 4; // Index of the Status column

      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryDisplayBloc, InventoryDisplayState>(
      builder: (context, inventoryState) {
        final productListState = context.watch<ProductListBloc>().state;
        final inventoryDisplayBloc = context.select((InventoryDisplayBloc b) => b);
        final notArchived =
            productListState.allProducts.where((p) => p.archiveStatus == 0).toList();
        final filtered = inventoryState.filteredProducts;

        return TableThemeData(
            child: PaginatedDataTable(
          showFirstLastButtons: true,
          showCheckboxColumn: false,
          horizontalMargin: 20,
          columnSpacing: 16,
          sortColumnIndex: _getSortColumnIndex(inventoryState.sortBy),
          sortAscending: inventoryState.sortAscending,
          checkboxHorizontalMargin: 0,
          columns: [
            DataColumn(
              label: Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120),
                  child: Row(
                    children: [
                      const Text('Name', style: TextStyles.strong),
                      if (_getSortColumnIndex(inventoryState.sortBy) != 0) ...[
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
                // Simply toggle between ascending and descending based on current sort type
                if (inventoryState.sortBy == InventoryDisplaySortBy.nameAscending ||
                    inventoryState.sortBy == InventoryDisplaySortBy.nameDescending) {
                  // If already sorting by name, just dispatch the same sort type to toggle direction
                  inventoryDisplayBloc.add(InventoryDisplaySortEvent(inventoryState.sortBy));
                } else {
                  // If not already sorting by name, start with ascending
                  inventoryDisplayBloc
                      .add(const InventoryDisplaySortEvent(InventoryDisplaySortBy.nameAscending));
                }
              },
            ),
            DataColumn(
              label: Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120),
                  child: Row(
                    children: [
                      const Text('Category', style: TextStyles.strong),
                      if (_getSortColumnIndex(inventoryState.sortBy) != 1) ...[
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
                if (inventoryState.sortBy == InventoryDisplaySortBy.categoryAscending ||
                    inventoryState.sortBy == InventoryDisplaySortBy.categoryDescending) {
                  inventoryDisplayBloc.add(InventoryDisplaySortEvent(inventoryState.sortBy));
                } else {
                  inventoryDisplayBloc.add(
                      const InventoryDisplaySortEvent(InventoryDisplaySortBy.categoryAscending));
                }
              },
            ),
            DataColumn(
              label: Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Row(
                    children: [
                      const Text('Sale Price', style: TextStyles.strong),
                      if (_getSortColumnIndex(inventoryState.sortBy) != 2) ...[
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
                if (inventoryState.sortBy == InventoryDisplaySortBy.priceAscending ||
                    inventoryState.sortBy == InventoryDisplaySortBy.priceDescending) {
                  inventoryDisplayBloc.add(InventoryDisplaySortEvent(inventoryState.sortBy));
                } else {
                  inventoryDisplayBloc
                      .add(const InventoryDisplaySortEvent(InventoryDisplaySortBy.priceAscending));
                }
              },
            ),
            DataColumn(
              label: Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Row(
                    children: [
                      const Text('Quantity', style: TextStyles.strong),
                      if (_getSortColumnIndex(inventoryState.sortBy) != 3) ...[
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
                if (inventoryState.sortBy == InventoryDisplaySortBy.stockAscending ||
                    inventoryState.sortBy == InventoryDisplaySortBy.stockDescending) {
                  inventoryDisplayBloc.add(InventoryDisplaySortEvent(inventoryState.sortBy));
                } else {
                  inventoryDisplayBloc
                      .add(const InventoryDisplaySortEvent(InventoryDisplaySortBy.stockAscending));
                }
              },
            ),
            DataColumn(
              label: Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Row(
                    children: [
                      const Text('Status', style: TextStyles.strong),
                      if (_getSortColumnIndex(inventoryState.sortBy) != 4) ...[
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
                inventoryDisplayBloc.add(
                  const InventoryDisplaySortEvent(InventoryDisplaySortBy.urgencyAscending),
                );
              },
            ),
            if (context.select((AuthenticationBloc b) => b.state.user?.accessLevel) ==
                AccessLevel.administrator)
              DataColumn(
                label: Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 60),
                    child: const Text('', style: TextStyles.strong),
                  ),
                ),
              ),
          ],
          source: ProductDataSource(context: context, products: filtered ?? notArchived),
        ));
      },
    );
  }
}

class ProductDataSource extends DataTableSource {
  ProductDataSource({
    required this.context,
    required this.products,
  });

  final List<Product> products;
  final BuildContext context;
  @override
  DataRow? getRow(int index) {
    final accessLevel = context.read<AuthenticationBloc>().state.user?.accessLevel;
    final product = products[index];
    return DataRowMapper.mapProductToRow(
      product,
      viewAction: () {
        unawaited(
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (dialogContext) {
              return ProductInformationContentDialog(
                dialogContext: dialogContext,
                product: product,
              );
            },
          ),
        );
      },
      editAction: accessLevel == AccessLevel.administrator
          ? () => context.navigateWithExtra(AppRoutes.admin.editProduct, product)
          : null,
      orderAction: accessLevel == AccessLevel.administrator
          ? () => context.navigateWithExtra(AppRoutes.admin.createRestockOrder.withProduct, product)
          : null,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => 0;
}
