import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/data_table_place_holder.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';

class InventoryPanePage extends StatefulWidget {
  const InventoryPanePage({super.key});

  @override
  State<InventoryPanePage> createState() => _InventoryPanePageState();
}

class _InventoryPanePageState extends State<InventoryPanePage> {
  late final AnimatedScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: AppPadding.panePadding,
          child: PageHeader(),
        ),
        Spacing.v4,
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.panePadding.horizontal / 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  InventorySummary(),
                  ProductListSection(),
                ].withSpacing(() => Spacing.v16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeadingText('Products'),
        const Spacer(flex: 1),
        TextButton('Manage Categories', onPressed: () {
          const route = AppRoutes.categoriesPage;
          context
              .read<NavigationBloc>()
              .goIndex(RouteIndexMapper.of(context).getIndexFromRoute(route)!);
        }),
        TextButtonFilled('New Product', onPressed: () {
          const route = AppRoutes.createProductPage;
          context
              .read<NavigationBloc>()
              .goIndex(RouteIndexMapper.of(context).getIndexFromRoute(route)!);
        }),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class InventorySummary extends StatelessWidget {
  const InventorySummary({super.key});

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
        LayoutMode.builder(builder: (context, layoutMode) {
          switch (layoutMode) {
            case LayoutMode.wide:
              return IntrinsicHeight(
                child: Row(
                  children: [
                    ActiveCountCard(value: activeCount.toString()),
                    LowStockCountCard(value: lowStockCount.toString()),
                    HangingCountCard(value: deadCount.toString()),
                    FastMovingCountCard(value: fastMovingCount.toString()),
                  ].withSpacing(() => Spacing.h16),
                ),
              );
            case LayoutMode.constrained:
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        ActiveCountCard(value: activeCount.toString()),
                        LowStockCountCard(value: lowStockCount.toString()),
                      ].withSpacing(() => Spacing.h8),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        HangingCountCard(value: deadCount.toString()),
                        FastMovingCountCard(value: fastMovingCount.toString()),
                      ].withSpacing(() => Spacing.h8),
                    ),
                  ),
                ].withSpacing(() => Spacing.v8),
              );
            case LayoutMode.compact:
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActiveCountCard(value: activeCount.toString(), isExpanded: false),
                  LowStockCountCard(value: lowStockCount.toString(), isExpanded: false),
                  HangingCountCard(value: deadCount.toString(), isExpanded: false),
                  FastMovingCountCard(value: fastMovingCount.toString(), isExpanded: false),
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
      : super(
          'Active Products',
          icon: const Icon(FluentIcons.product),
        );
}

class LowStockCountCard extends KPICard {
  const LowStockCountCard({super.key, required super.value, super.isExpanded})
      : super(
          'Low Stock Products',
          icon: const Icon(FluentIcons.product_warning),
        );
}

class HangingCountCard extends KPICard {
  const HangingCountCard({super.key, required super.value, super.isExpanded})
      : super(
          'Hanging Products',
          icon: const Icon(FluentIcons.market_down),
        );
}

class FastMovingCountCard extends KPICard {
  const FastMovingCountCard({super.key, required super.value, super.isExpanded})
      : super(
          'Fast Moving Products',
          icon: const Icon(FluentIcons.market),
        );
}

class SearchRow extends StatelessWidget {
  const SearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: TextBox(placeholder: "Search"),
        ),
        const CategoryButton(),
        const SortByButton(),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h8),
    );
  }
}

class CategoryButton extends StatelessWidget {
  const CategoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return DropDownButton(
      title: const Padding(
        padding: AppPadding.a4,
        child: ButtonText('Category'),
      ),
      items: [
        MenuFlyoutItem(
          text: const BodyText('Category 1'),
          onPressed: () {},
        ),
      ],
    );
  }
}

class SortByButton extends StatelessWidget {
  const SortByButton({super.key});

  @override
  Widget build(BuildContext context) {
    return DropDownButton(
      title: const Padding(
        padding: AppPadding.a4,
        child: ButtonText('Sort By'),
      ),
      items: [
        MenuFlyoutItem(text: const BodyText('Name Ascending'), onPressed: () {}),
        MenuFlyoutItem(text: const BodyText('Name Descending'), onPressed: () {}),
        const MenuFlyoutSeparator(),
        MenuFlyoutItem(text: const BodyText('Stock Ascending'), onPressed: () {}),
        MenuFlyoutItem(text: const BodyText('Stock Descending'), onPressed: () {}),
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

class ProductsDataTable extends StatefulWidget {
  const ProductsDataTable({super.key});

  @override
  State<ProductsDataTable> createState() => _ProductsDataTableState();
}

class _ProductsDataTableState extends State<ProductsDataTable> {
  static const names = ['Name', 'Category', 'Price', 'Cost', 'Quantity', 'Actions'];

  late final AnimatedScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Widget buildTable(BuildContext context) {
    final state = context.watch<ProductListBloc>().state;
    if (state.status == DataStatus.loading) {
      return const Center(child: ProgressRing());
    }

    final allProducts = state.allProducts.where((p) => p.archiveStatus == 0).toList();
    if (allProducts.isEmpty) {
      return const DataTablePlaceHolder(FluentIcons.product_list, 'Products');
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: true,
          columns: [
            for (final data in names) DataColumn(label: Text(data)),
          ],
          rows: [
            for (final product in allProducts)
              DataRowMapper.mapProductToRow(
                product,
                editAction: () {
                  context.push(AppRoutes.editProductPage.path, extra: product);
                  context.read<NavigationBloc>().goOutsideOfNavigation();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(child: buildTable(context));
  }
}
