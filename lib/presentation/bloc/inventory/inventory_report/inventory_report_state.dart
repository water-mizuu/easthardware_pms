part of 'inventory_report_bloc.dart';

class InventoryReportState extends Equatable {
  const InventoryReportState({
    required this.allProducts,
    required this.queryData,
    this.isGenerating = false,
    this.selectedDate,
    this.overlayEntry,
  });

  final WeakReference<List<Product>> allProducts;
  final InventoryQueryData queryData;
  final bool isGenerating;
  final DateTime? selectedDate;
  final OverlayEntry? overlayEntry;

  DateTime get effectiveSelectedDate => selectedDate ?? DateTime.now();

  InventoryReportState Function({
    List<Product> allProducts,
    InventoryQueryData queryData,
    bool isGenerating,
    DateTime? selectedDate,
    OverlayEntry? overlayEntry,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
      Object? selectedDate = undefined,
      Object? overlayEntry = undefined,
    }) {
      return InventoryReportState(
        allProducts: allProducts == undefined
            ? this.allProducts
            : WeakReference(allProducts as List<Product>),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
        selectedDate: selectedDate.or(this.selectedDate),
        overlayEntry: overlayEntry.or(this.overlayEntry),
      );
    };
  }

  @override
  List<Object?> get props => [
        allProducts,
        queryData,
        isGenerating,
        selectedDate,
        overlayEntry,
      ];
}
