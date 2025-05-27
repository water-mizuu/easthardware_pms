import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/data_table_place_holder.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scroll_animator/scroll_animator.dart';

enum LayoutMode { wide, constrained, compact }

class InventoryPanePage extends StatelessWidget {
  const InventoryPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutMode = width > 850
            ? LayoutMode.wide
            : width > 0.85
                ? LayoutMode.constrained
                : LayoutMode.compact;

        return Provider.value(
          value: layoutMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(),
              const InventorySummary(),
              const ProductListSection(),
            ].withSpacing(() => Spacing.v16),
          ),
        );
      }),
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
        Row(
          children: [
            TextButton('Manage Categories', onPressed: () {
              const route = AppRoutes.categoriesPage;
              context
                  .read<NavigationBloc>()
                  .add(NavigationIndexChanged(index: RouteIndexMapper.getIndexFromRoute(route)!));
            }),
            TextButtonFilled('New Product', onPressed: () {
              const route = AppRoutes.createProductPage;
              context
                  .read<NavigationBloc>()
                  .add(NavigationIndexChanged(index: RouteIndexMapper.getIndexFromRoute(route)!));
            })
          ].withSpacing(() => Spacing.h16),
        ),
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
        Builder(builder: (context) {
          final layoutMode = context.watch<LayoutMode>();
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
                      ].withSpacing(() => Spacing.h16),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        HangingCountCard(value: deadCount.toString()),
                        FastMovingCountCard(value: fastMovingCount.toString()),
                      ].withSpacing(() => Spacing.h16),
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
  const SearchRow({
    super.key,
  });

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
    return Expanded(
      flex: 4,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubheadingText('List of Products'),
          const SearchRow(),
          const ProductsDataTable(),
        ].withSpacing(() => Spacing.v8),
      ),
    );
  }
}

class ProductsDataTable extends StatefulWidget {
  const ProductsDataTable({
    super.key,
  });

  @override
  State<ProductsDataTable> createState() => _ProductsDataTableState();
}

class _ProductsDataTableState extends State<ProductsDataTable> {
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
    final state = context.watch<ProductListBloc>().state;
    if (state.status == DataStatus.loading) {
      return const Expanded(
        child: Center(
          child: ProgressRing(),
        ),
      );
    }

    // We only want to show products that are not archived
    final allProducts = state.allProducts.where((p) => p.archiveStatus == 0).toList();
    if (allProducts.isEmpty) {
      return const DataTablePlaceHolder(FluentIcons.product_list, 'Products');
    }

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: DataTable(
            showCheckboxColumn: true,
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Cost')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final product in allProducts)
                DataRowMapper.mapProductToRow(product, () {
                  context.push(AppRoutes.editProductPage, extra: product);
                }),
            ],
          ),
        ),
      ),
    );
  }
}
