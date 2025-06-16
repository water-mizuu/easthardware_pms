import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/data_table_place_holder.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class InventoryPanePage extends StatefulWidget {
  const InventoryPanePage({super.key});

  @override
  State<InventoryPanePage> createState() => _InventoryPanePageState();
}

class _InventoryPanePageState extends State<InventoryPanePage> {
  late final AnimatedScrollController _scrollController;
  late final InventoryDisplayBloc _inventoryDisplayBloc;
  WeakReference<List<Product>>? _productListBlocRef;

  @override
  void initState() {
    super.initState();

    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
    _inventoryDisplayBloc = InventoryDisplayBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final productList = context.watch<ProductListBloc>().state.allProducts;
    if (productList != _productListBlocRef?.target) {
      _productListBlocRef = WeakReference(productList);
      _inventoryDisplayBloc.add(InventoryDisplayItemsUpdatedEvent(_productListBlocRef!));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inventoryDisplayBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inventoryDisplayBloc,
      child: Column(
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
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.panePadding.horizontal / 2,
                ),
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
          context.navigate(AppRoutes.admin.inventory);
        }),
        TextButtonFilled('New Product', onPressed: () {
          context.navigate(AppRoutes.admin.createProduct);
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
    final activeCount = state.allProducts.where((product) => product.archivedStatus == 0).length;
    final lowStockCount = state.lowStockProducts.length;
    final fastMovingCount = state.fastMovingProducts.length;
    final deadCount = state.deadStockProducts.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Inventory Summary'),
        LayoutMode.builder((context, layoutMode) {
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
        const SortByButton(),
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

class SortByButton extends StatelessWidget {
  const SortByButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedCategory = context.select((InventoryDisplayBloc b) => b.state.sortBy);

    return DropDownButton(
      title: Padding(
        padding: AppPadding.a4,
        child: selectedCategory != null
            ? ButtonText(selectedCategory.name, overflow: TextOverflow.fade)
            : const ButtonText('Sort By'),
      ),
      items: [
        MenuFlyoutItem(
          text: const BodyText('Name Ascending'),
          onPressed: () {
            _chooseSort(context, InventoryDisplaySortBy.nameAscending);
          },
        ),
        MenuFlyoutItem(
          text: const BodyText('Name Descending'),
          onPressed: () {
            _chooseSort(context, InventoryDisplaySortBy.nameDescending);
          },
        ),
        const MenuFlyoutSeparator(),
        MenuFlyoutItem(
          text: const BodyText('Stock Ascending'),
          onPressed: () {
            _chooseSort(context, InventoryDisplaySortBy.stockAscending);
          },
        ),
        MenuFlyoutItem(
          text: const BodyText('Stock Descending'),
          onPressed: () {
            _chooseSort(context, InventoryDisplaySortBy.stockDescending);
          },
        ),
      ],
    );
  }

  void _chooseSort(BuildContext context, InventoryDisplaySortBy sortBy) {
    context.read<InventoryDisplayBloc>().add(InventoryDisplaySortEvent(sortBy));
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
  static const double cellHeight = 36.0;
  static final Map<String, SpanExtent> _rowExtents = {
    "Name": const MaxSpanExtent(FixedSpanExtent(240.00), FractionalSpanExtent(0.33)),
    "Category": const MaxSpanExtent(FixedSpanExtent(80.00), FractionalSpanExtent(0.33)),
    "Price": const FixedSpanExtent(120),
    "Cost": const FixedSpanExtent(120),
    "Quantity": const FixedSpanExtent(120),
    "Actions": const MaxSpanExtent(FixedSpanExtent(80.00), RemainingSpanExtent()),
  };

  late final AnimatedScrollController _verticalScrollController;
  late final AnimatedScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();

    _verticalScrollController =
        AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
    _horizontalScrollController =
        AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: AppPadding.cardPadding,
      child: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state.status == DataStatus.loading) {
            return const Center(child: ProgressRing());
          }

          final allProducts = state.allProducts.where((p) => p.archivedStatus == 0).toList();
          final displayProducts =
              context.select((InventoryDisplayBloc b) => b.state.filteredProducts);

          if (allProducts.isEmpty) {
            return const DataTablePlaceHolder(FluentIcons.product_list, 'Products');
          }

          final matrix = [
            [
              for (final columnName in _rowExtents.keys)
                Text(columnName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            for (final product in displayProducts ?? allProducts) //
              if (DataRowMapper.mapProductToRow(product, editAction: () {
                context.navigateWithExtra(AppRoutes.admin.editProduct, product);
              })
                  case final row)
                [
                  for (final cell in row.cells)
                    ColoredBox(
                      color: row.color?.resolve({}) ?? Colors.transparent,
                      child: cell.child,
                    )
                ]
          ];

          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: cellHeight * 4,
              maxHeight: matrix.length * cellHeight,
            ),
            child: TableView.builder(
              verticalDetails: ScrollableDetails.vertical(
                controller: _verticalScrollController,
              ),
              horizontalDetails: ScrollableDetails.horizontal(
                controller: _horizontalScrollController,
              ),

              /// Fixed counts for easier rendering.
              columnCount: _rowExtents.length,
              rowCount: matrix.length,

              /// Use the extents defined in _rowExtents.
              columnBuilder: (index) => TableSpan(extent: _rowExtents.values.elementAt(index)),
              rowBuilder: (index) => const TableSpan(extent: FixedSpanExtent(cellHeight)),

              /// We refer to the matrix to get the cell content.
              cellBuilder: (_, vicinity) =>
                  TableViewCell(child: matrix[vicinity.row][vicinity.column]),
            ),
          );
        },
      ),
    );
  }
}
