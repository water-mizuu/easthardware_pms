import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/common/reports_globals.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/'
    'extensions/sales_by_category_datum.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

/// Extension to make working with the (Product, SalesExtras) tuple easier
extension SalesExtrasPair on (Product, SalesExtras) {
  Product get product => $1;
  SalesExtras get extras => $2;

  double get salePrice => product.salePrice;
  double get orderCost => product.orderCost;

  double get unitsSold => extras.unitsSold;
  double get unitsOrdered => extras.unitsOrdered;
  double get totalRevenue => unitsSold * product.salePrice;
  double get totalOrderCost => unitsOrdered * product.orderCost;
  double get grossProfit => totalRevenue - totalOrderCost;
}

class SalesExtras with EquatableMixin {
  const SalesExtras({
    required this.product,
    required this.unitsSold,
    required this.unitsOrdered,
  });

  final Product product;
  final double unitsSold;
  final double unitsOrdered;

  SalesExtras Function({
    Product product,
    double unitsSold,
    double unitsOrdered,
  }) get copyWith {
    return ({
      Object? product = undefined,
      Object? unitsSold = undefined,
      Object? unitsOrdered = undefined,
    }) {
      return SalesExtras(
        product: product.or(this.product),
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
    return SalesQueryData(
      startDate: ReportsGlobals.defaultStartDate,
      endDate: ReportsGlobals.defaultEndDate,
    );
  }
  const SalesQueryData({
    required this.startDate,
    required this.endDate,
    this.salesByProductData,
    this.salesByCategoryData,
    this.productSortBy = SalesByProductReportSortBy.skuAscending,
    this.categorySortBy = SalesByCategoryReportSortBy.categoryNameAscending,
    this.rowLimit,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Product, SalesExtras)>? salesByProductData;
  final List<SalesByCategoryDatum>? salesByCategoryData;
  final SalesByProductReportSortBy productSortBy;
  final SalesByCategoryReportSortBy categorySortBy;
  final int? rowLimit;

  SalesQueryData Function({
    DateTime startDate,
    DateTime endDate,
    List<(Product, SalesExtras)>? salesByProductData,
    List<SalesByCategoryDatum>? salesByCategoryData,
    SalesByProductReportSortBy productSortBy,
    SalesByCategoryReportSortBy categorySortBy,
    int? rowLimit,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? salesByProductData = undefined,
      Object? salesByCategoryData = undefined,
      Object? productSortBy = undefined,
      Object? categorySortBy = undefined,
      Object? rowLimit = undefined,
    }) {
      return SalesQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        salesByProductData: salesByProductData.or(this.salesByProductData),
        salesByCategoryData: salesByCategoryData.or(this.salesByCategoryData),
        productSortBy: productSortBy.or(this.productSortBy),
        categorySortBy: categorySortBy.or(this.categorySortBy),
        rowLimit: rowLimit.or(this.rowLimit),
      );
    };
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        salesByProductData,
        salesByCategoryData,
        productSortBy,
        categorySortBy,
        rowLimit,
      ];

  List<(Product, SalesExtras)>? get salesByProductDataWithTake {
    if (rowLimit != null && salesByProductData != null) {
      return salesByProductData?.take(rowLimit!).toList();
    }
    return salesByProductData;
  }

  List<SalesByCategoryDatum>? get salesByCategoryDataWithTake {
    if (rowLimit != null && salesByCategoryData != null) {
      return salesByCategoryData?.take(rowLimit!).toList();
    }
    return salesByCategoryData;
  }
}

enum SalesByProductReportSortBy {
  skuAscending('SKU (A-Z)'),
  skuDescending('SKU (Z-A)'),
  productNameAscending('Product Name (A-Z)'),
  productNameDescending('Product Name (Z-A)'),
  unitsSoldAscending('Units Sold (Low to High)'),
  unitsSoldDescending('Units Sold (High to Low)'),
  sellingPriceAscending('Selling Price (Low to High)'),
  sellingPriceDescending('Selling Price (High to Low)'),
  totalRevenueAscending('Total Revenue (Low to High)'),
  totalRevenueDescending('Total Revenue (High to Low)'),
  totalOrderCostAscending('Total Order Cost (Low to High)'),
  totalOrderCostDescending('Total Order Cost (High to Low)'),
  grossProfitAscending('Gross Profit (Low to High)'),
  grossProfitDescending('Gross Profit (High to Low)'),
  ;

  const SalesByProductReportSortBy(this.name);

  final String name;

  SalesByProductReportSortBy get opposite {
    switch (this) {
      case SalesByProductReportSortBy.skuAscending:
        return SalesByProductReportSortBy.skuDescending;
      case SalesByProductReportSortBy.skuDescending:
        return SalesByProductReportSortBy.skuAscending;
      case SalesByProductReportSortBy.productNameAscending:
        return SalesByProductReportSortBy.productNameDescending;
      case SalesByProductReportSortBy.productNameDescending:
        return SalesByProductReportSortBy.productNameAscending;
      case SalesByProductReportSortBy.unitsSoldAscending:
        return SalesByProductReportSortBy.unitsSoldDescending;
      case SalesByProductReportSortBy.unitsSoldDescending:
        return SalesByProductReportSortBy.unitsSoldAscending;
      case SalesByProductReportSortBy.sellingPriceAscending:
        return SalesByProductReportSortBy.sellingPriceDescending;
      case SalesByProductReportSortBy.sellingPriceDescending:
        return SalesByProductReportSortBy.sellingPriceAscending;
      case SalesByProductReportSortBy.totalRevenueAscending:
        return SalesByProductReportSortBy.totalRevenueDescending;
      case SalesByProductReportSortBy.totalRevenueDescending:
        return SalesByProductReportSortBy.totalRevenueAscending;
      case SalesByProductReportSortBy.totalOrderCostAscending:
        return SalesByProductReportSortBy.totalOrderCostDescending;
      case SalesByProductReportSortBy.totalOrderCostDescending:
        return SalesByProductReportSortBy.totalOrderCostAscending;
      case SalesByProductReportSortBy.grossProfitAscending:
        return SalesByProductReportSortBy.grossProfitDescending;
      case SalesByProductReportSortBy.grossProfitDescending:
        return SalesByProductReportSortBy.grossProfitAscending;
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
      case SalesByProductReportSortBy.skuAscending:
        return productA.sku.compareToLowercase(productB.sku);
      case SalesByProductReportSortBy.skuDescending:
        return productB.sku.compareToLowercase(productA.sku);
      case SalesByProductReportSortBy.productNameAscending:
        return productA.name.compareToLowercase(productB.name);
      case SalesByProductReportSortBy.productNameDescending:
        return productB.name.compareToLowercase(productA.name);
      case SalesByProductReportSortBy.unitsSoldAscending:
        return extrasA.unitsSold.compareTo(extrasB.unitsSold);
      case SalesByProductReportSortBy.unitsSoldDescending:
        return extrasB.unitsSold.compareTo(extrasA.unitsSold);
      case SalesByProductReportSortBy.sellingPriceAscending:
        return productA.salePrice.compareTo(productB.salePrice);
      case SalesByProductReportSortBy.sellingPriceDescending:
        return productB.salePrice.compareTo(productA.salePrice);
      case SalesByProductReportSortBy.totalRevenueAscending:
        return totalRevenueA.compareTo(totalRevenueB);
      case SalesByProductReportSortBy.totalRevenueDescending:
        return totalRevenueB.compareTo(totalRevenueA);
      case SalesByProductReportSortBy.totalOrderCostAscending:
        return totalOrderCostA.compareTo(totalOrderCostB);
      case SalesByProductReportSortBy.totalOrderCostDescending:
        return totalOrderCostB.compareTo(totalOrderCostA);
      case SalesByProductReportSortBy.grossProfitAscending:
        return totalGrossA.compareTo(totalGrossB);
      case SalesByProductReportSortBy.grossProfitDescending:
        return totalGrossB.compareTo(totalGrossA);
    }
  }
}

enum SalesByCategoryReportSortBy {
  categoryNameAscending('Category Name (A-Z)'),
  categoryNameDescending('Category Name (Z-A)'),
  unitsSoldAscending('Units Sold (Low to High)'),
  unitsSoldDescending('Units Sold (High to Low)'),
  unitsOrderedAscending('Units Ordered (Low to High)'),
  unitsOrderedDescending('Units Ordered (High to Low)'),
  sellingPriceAscending('Selling Price (Low to High)'),
  sellingPriceDescending('Selling Price (High to Low)'),
  totalRevenueAscending('Total Revenue (Low to High)'),
  totalRevenueDescending('Total Revenue (High to Low)'),
  totalOrderCostAscending('Total Order Cost (Low to High)'),
  totalOrderCostDescending('Total Order Cost (High to Low)'),
  grossProfitAscending('Gross Profit (Low to High)'),
  grossProfitDescending('Gross Profit (High to Low)'),
  ;

  const SalesByCategoryReportSortBy(this.name);

  final String name;

  SalesByCategoryReportSortBy get opposite {
    switch (this) {
      case SalesByCategoryReportSortBy.categoryNameAscending:
        return SalesByCategoryReportSortBy.categoryNameDescending;
      case SalesByCategoryReportSortBy.categoryNameDescending:
        return SalesByCategoryReportSortBy.categoryNameAscending;
      case SalesByCategoryReportSortBy.unitsOrderedAscending:
        return SalesByCategoryReportSortBy.unitsOrderedDescending;
      case SalesByCategoryReportSortBy.unitsOrderedDescending:
        return SalesByCategoryReportSortBy.unitsOrderedAscending;
      case SalesByCategoryReportSortBy.unitsSoldAscending:
        return SalesByCategoryReportSortBy.unitsSoldDescending;
      case SalesByCategoryReportSortBy.unitsSoldDescending:
        return SalesByCategoryReportSortBy.unitsSoldAscending;
      case SalesByCategoryReportSortBy.sellingPriceAscending:
        return SalesByCategoryReportSortBy.sellingPriceDescending;
      case SalesByCategoryReportSortBy.sellingPriceDescending:
        return SalesByCategoryReportSortBy.sellingPriceAscending;
      case SalesByCategoryReportSortBy.totalRevenueAscending:
        return SalesByCategoryReportSortBy.totalRevenueDescending;
      case SalesByCategoryReportSortBy.totalRevenueDescending:
        return SalesByCategoryReportSortBy.totalRevenueAscending;
      case SalesByCategoryReportSortBy.totalOrderCostAscending:
        return SalesByCategoryReportSortBy.totalOrderCostDescending;
      case SalesByCategoryReportSortBy.totalOrderCostDescending:
        return SalesByCategoryReportSortBy.totalOrderCostAscending;
      case SalesByCategoryReportSortBy.grossProfitAscending:
        return SalesByCategoryReportSortBy.grossProfitDescending;
      case SalesByCategoryReportSortBy.grossProfitDescending:
        return SalesByCategoryReportSortBy.grossProfitAscending;
    }
  }

  int compare(SalesByCategoryDatum a, SalesByCategoryDatum b) {
    late final totalRevenueA = a.totalRevenue;
    late final totalRevenueB = b.totalRevenue;

    late final totalOrderCostA = a.orderCost;
    late final totalOrderCostB = b.orderCost;

    late final totalGrossA = totalRevenueA - totalOrderCostA;
    late final totalGrossB = totalRevenueB - totalOrderCostB;

    switch (this) {
      case SalesByCategoryReportSortBy.categoryNameAscending:
        return a.category.name.compareToLowercase(b.category.name);
      case SalesByCategoryReportSortBy.categoryNameDescending:
        return b.category.name.compareToLowercase(a.category.name);
      case SalesByCategoryReportSortBy.unitsSoldAscending:
        return a.unitsSold.compareTo(b.unitsSold);
      case SalesByCategoryReportSortBy.unitsSoldDescending:
        return b.unitsSold.compareTo(a.unitsSold);
      case SalesByCategoryReportSortBy.unitsOrderedAscending:
        return a.unitsOrdered.compareTo(b.unitsOrdered);
      case SalesByCategoryReportSortBy.unitsOrderedDescending:
        return b.unitsOrdered.compareTo(a.unitsOrdered);
      case SalesByCategoryReportSortBy.sellingPriceAscending:
        return a.salePrice.compareTo(b.salePrice);
      case SalesByCategoryReportSortBy.sellingPriceDescending:
        return b.salePrice.compareTo(a.salePrice);
      case SalesByCategoryReportSortBy.totalRevenueAscending:
        return totalRevenueA.compareTo(totalRevenueB);
      case SalesByCategoryReportSortBy.totalRevenueDescending:
        return totalRevenueB.compareTo(totalRevenueA);
      case SalesByCategoryReportSortBy.totalOrderCostAscending:
        return totalOrderCostA.compareTo(totalOrderCostB);
      case SalesByCategoryReportSortBy.totalOrderCostDescending:
        return totalOrderCostB.compareTo(totalOrderCostA);
      case SalesByCategoryReportSortBy.grossProfitAscending:
        return totalGrossA.compareTo(totalGrossB);
      case SalesByCategoryReportSortBy.grossProfitDescending:
        return totalGrossB.compareTo(totalGrossA);
    }
  }
}
