import 'package:fluent_ui/fluent_ui.dart';

class PaginatedTable extends StatelessWidget {
  const PaginatedTable.sample({
    super.key,
    this.minheight,
    this.maxheight,
    this.headers = const [
      TableHeader(title: Text('Header 1')),
      TableHeader(title: Text('Header 2')),
      TableHeader(title: Text('Header 3')),
    ],
    this.rows = const [
      TableRow(cells: [Text('Row 1, Cell 1'), Text('Row 1, Cell 2'), Text('Row 1, Cell 3')]),
      TableRow(cells: [Text('Row 2, Cell 1'), Text('Row 2, Cell 2'), Text('Row 2, Cell 3')]),
    ],
    this.rowsPerPage = 10,
    this.currentPage = 1,
    this.onPageChanged,
    this.onRowsPerPageChanged,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.isExpanded = false,
  });

  const PaginatedTable({
    super.key,
    this.minheight,
    this.maxheight,
    required this.headers,
    required this.rows,
    this.rowsPerPage,
    this.currentPage,
    this.onPageChanged,
    this.onRowsPerPageChanged,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.isExpanded = false,
  });

  final double? minheight;
  final double? maxheight;
  final List<TableHeader> headers;
  final List<TableRow> rows;
  final int? rowsPerPage;
  final int? currentPage;
  final Function(int)? onPageChanged;
  final Function(int)? onRowsPerPageChanged;
  final bool? showPageSizeSelector;
  final List<int> pageSizeOptions;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    // Calculate the number of pages based on rows and rowsPerPage
    final totalRows = rows.length;
    final effectiveRowsPerPage = rowsPerPage ?? 10;
    final totalPages = (totalRows / effectiveRowsPerPage).ceil();

    // Create the pagination controls
    final Widget paginationControls = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showPageSizeSelector == true)
            DropDownButton(
                items: pageSizeOptions
                    .map((size) => MenuFlyoutItem(
                          text: Text(size.toString()),
                          onPressed: () {
                            if (onRowsPerPageChanged != null) {
                              onRowsPerPageChanged!(size);
                            }
                          },
                        ))
                    .toList()),
          Text('Page ${currentPage ?? 1} of $totalPages'),
          if (totalPages > 1)
            IconButton(
              icon: const Icon(FluentIcons.chevron_right),
              onPressed: () {
                if (onPageChanged != null && currentPage != null) {
                  onPageChanged!(currentPage! + 1);
                }
              },
            ),
        ],
      ),
    );

    final Widget tableContent = Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          Row(
            children: [
              for (final header in headers)
                TableHeader(
                  title: header.title,
                  icon: header.icon,
                  flex: header.flex,
                  width: header.width,
                  height: header.height,
                  isExpanded: isExpanded,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: totalRows,
              itemBuilder: (context, index) {
                final rowIndex = index + ((currentPage ?? 1) - 1) * effectiveRowsPerPage;
                if (rowIndex >= totalRows) return const SizedBox.shrink();
                return rows[rowIndex % rows.length]; // Use modulo to cycle through rows
              },
            ),
          ),
          // Pagination controls
          paginationControls,
        ],
      ),
    );

    if (isExpanded || (minheight == null && maxheight == null)) {
      return SizedBox.expand(
        child: tableContent,
      );
    }

    // Otherwise use ConstrainedBox with provided or default constraints
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minheight ?? 400,
        maxHeight: maxheight ?? 600,
      ),
      child: tableContent,
    );
  }
}

class TableHeader extends StatelessWidget {
  const TableHeader({
    super.key,
    required this.title,
    this.icon,
    this.flex,
    this.width,
    this.height,
    this.isExpanded = true,
  });
  final Widget title;
  final Icon? icon;
  final int? flex;
  final double? width;
  final double? height;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (!isExpanded || width != null) {
      return SizedBox(
        width: width,
        height: height ?? 40,
        child: Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Expanded(child: title),
          ],
        ),
      );
    } else {
      return Expanded(
        flex: flex ?? 1,
        child: Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            title,
          ],
        ),
      );
    }
  }
}

class TableRow extends StatelessWidget {
  const TableRow({
    super.key,
    required this.cells,
    this.height,
    this.isExpanded = true,
    this.flex,
    this.onCellTap,
    this.showCheckbox = false,
  });

  final List<Widget> cells;
  final double? height;
  final bool isExpanded;
  final int? flex;
  final Function(int)? onCellTap;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 40,
      child: Row(
        children: [
          if (showCheckbox)
            Checkbox(
              checked: false,
              onChanged: (value) {
                // Handle checkbox state change
              },
            ),
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: flex ?? 1,
              child: GestureDetector(
                onTap: () {
                  if (onCellTap != null) {
                    onCellTap!(i);
                  }
                },
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }
}
