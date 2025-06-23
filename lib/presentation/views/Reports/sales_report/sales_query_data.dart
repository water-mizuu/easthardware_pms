import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

class SalesExtras with EquatableMixin {
  const SalesExtras({
    required this.unitsSold,
    required this.unitsOrdered,
  });

  final double unitsSold;
  final double unitsOrdered;

  SalesExtras Function({
    double? unitsSold,
    double? unitsOrdered,
  }) get copyWith {
    return ({
      Object? unitsSold = undefined,
      Object? unitsOrdered = undefined,
    }) {
      return SalesExtras(
        unitsSold: unitsSold.or(this.unitsSold),
        unitsOrdered: unitsOrdered.or(this.unitsOrdered),
      );
    };
  }

  @override
  List<Object?> get props => [unitsSold, unitsOrdered];
}

class SalesQueryData with EquatableMixin {
  factory SalesQueryData.empty() {
    final now = DateTime.now().zeroedTime();

    return SalesQueryData(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }
  const SalesQueryData({
    required this.startDate,
    required this.endDate,
    this.salesData,
    this.sortBy = SalesReportSortBy.skuAscending,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Product, SalesExtras)>? salesData;
  final SalesReportSortBy sortBy;

  SalesQueryData Function({
    DateTime startDate,
    DateTime endDate,
    List<(Product, SalesExtras)>? salesData,
    SalesReportSortBy sortBy,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? salesData = undefined,
      Object? sortBy = undefined,
    }) {
      return SalesQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        salesData: salesData.or(this.salesData),
        sortBy: sortBy.or(this.sortBy),
      );
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, salesData, sortBy];
}

enum SalesReportSortBy {
  skuAscending('SKU Ascending'),
  skuDescending('SKU Descending'),
  productNameAscending('Product Name Ascending'),
  productNameDescending('Product Name Descending'),
  unitsSoldAscending('Units Sold Ascending'),
  unitsSoldDescending('Units Sold Descending'),
  sellingPriceAscending('Selling Price Ascending'),
  sellingPriceDescending('Selling Price Descending'),
  totalRevenueAscending('Total Revenue Ascending'),
  totalRevenueDescending('Total Revenue Descending'),
  totalOrderCostAscending('Total Order Cost Ascending'),
  totalOrderCostDescending('Total Order Cost Descending'),
  grossProfitAscending('Gross Profit Ascending'),
  grossProfitDescending('Gross Profit Descending'),
  ;

  const SalesReportSortBy(this.name);

  final String name;

  SalesReportSortBy get opposite {
    switch (this) {
      case SalesReportSortBy.skuAscending:
        return SalesReportSortBy.skuDescending;
      case SalesReportSortBy.skuDescending:
        return SalesReportSortBy.skuAscending;
      case SalesReportSortBy.productNameAscending:
        return SalesReportSortBy.productNameDescending;
      case SalesReportSortBy.productNameDescending:
        return SalesReportSortBy.productNameAscending;
      case SalesReportSortBy.unitsSoldAscending:
        return SalesReportSortBy.unitsSoldDescending;
      case SalesReportSortBy.unitsSoldDescending:
        return SalesReportSortBy.unitsSoldAscending;
      case SalesReportSortBy.sellingPriceAscending:
        return SalesReportSortBy.sellingPriceDescending;
      case SalesReportSortBy.sellingPriceDescending:
        return SalesReportSortBy.sellingPriceAscending;
      case SalesReportSortBy.totalRevenueAscending:
        return SalesReportSortBy.totalRevenueDescending;
      case SalesReportSortBy.totalRevenueDescending:
        return SalesReportSortBy.totalRevenueAscending;
      case SalesReportSortBy.totalOrderCostAscending:
        return SalesReportSortBy.totalOrderCostDescending;
      case SalesReportSortBy.totalOrderCostDescending:
        return SalesReportSortBy.totalOrderCostAscending;
      case SalesReportSortBy.grossProfitAscending:
        return SalesReportSortBy.grossProfitDescending;
      case SalesReportSortBy.grossProfitDescending:
        return SalesReportSortBy.grossProfitAscending;
    }
  }

  int compare((Product, SalesExtras) a, (Product, SalesExtras) b) {
    final (productA, extrasA) = a;
    final (productB, extrasB) = b;

    final isArchivedA = productA.archiveStatus == 1;
    final isArchivedB = productB.archiveStatus == 1;

    if (isArchivedA && !isArchivedB) {
      return 1; // A is archived, B is not
    } else if (!isArchivedA && isArchivedB) {
      return -1; // B is archived, A is not
    }

    late final totalRevenueA = extrasA.unitsSold * productA.salePrice;
    late final totalRevenueB = extrasB.unitsSold * productB.salePrice;

    late final totalOrderCostA = extrasA.unitsOrdered * productA.orderCost;
    late final totalOrderCostB = extrasB.unitsOrdered * productB.orderCost;

    late final totalGrossA = totalRevenueA - totalOrderCostA;
    late final totalGrossB = totalRevenueB - totalOrderCostB;

    switch (this) {
      case SalesReportSortBy.skuAscending:
        return productA.sku.compareTo(productB.sku);
      case SalesReportSortBy.skuDescending:
        return productB.sku.compareTo(productA.sku);
      case SalesReportSortBy.productNameAscending:
        return productA.name.compareTo(productB.name);
      case SalesReportSortBy.productNameDescending:
        return productB.name.compareTo(productA.name);
      case SalesReportSortBy.unitsSoldAscending:
        return extrasA.unitsSold.compareTo(extrasB.unitsSold);
      case SalesReportSortBy.unitsSoldDescending:
        return extrasB.unitsSold.compareTo(extrasA.unitsSold);
      case SalesReportSortBy.sellingPriceAscending:
        return productA.salePrice.compareTo(productB.salePrice);
      case SalesReportSortBy.sellingPriceDescending:
        return productB.salePrice.compareTo(productA.salePrice);
      case SalesReportSortBy.totalRevenueAscending:
        return totalRevenueA.compareTo(totalRevenueB);
      case SalesReportSortBy.totalRevenueDescending:
        return totalRevenueB.compareTo(totalRevenueA);
      case SalesReportSortBy.totalOrderCostAscending:
        return totalOrderCostA.compareTo(totalOrderCostB);
      case SalesReportSortBy.totalOrderCostDescending:
        return totalOrderCostB.compareTo(totalOrderCostA);
      case SalesReportSortBy.grossProfitAscending:
        return totalGrossA.compareTo(totalGrossB);
      case SalesReportSortBy.grossProfitDescending:
        return totalGrossB.compareTo(totalGrossA);
    }
  }
}
