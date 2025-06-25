import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/extensions/sales_by_category_datum.dart';
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
  double get totalCost => unitsOrdered * product.orderCost;
  double get grossProfit => totalRevenue - totalCost;
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
    final now = DateTime.now().zeroedTime();

    return SalesQueryData(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }
  const SalesQueryData({
    required this.startDate,
    required this.endDate,
    this.salesByProductData,
    this.salesByCategoryData,
    this.productSortBy = SalesByProductReportSortBy.skuAscending,
    this.categorySortBy = SalesByCategoryReportSortBy.categoryNameAscending,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<(Product, SalesExtras)>? salesByProductData;
  final List<SalesByCategoryDatum>? salesByCategoryData;
  final SalesByProductReportSortBy productSortBy;
  final SalesByCategoryReportSortBy categorySortBy;

  SalesQueryData Function({
    DateTime startDate,
    DateTime endDate,
    List<(Product, SalesExtras)>? salesByProductData,
    List<(List<(Product, SalesExtras)>, Category)>? salesByCategoryData,
    SalesByProductReportSortBy productSortBy,
    SalesByCategoryReportSortBy categorySortBy,
  }) get copyWith {
    return ({
      Object? startDate = undefined,
      Object? endDate = undefined,
      Object? salesByProductData = undefined,
      Object? salesByCategoryData = undefined,
      Object? productSortBy = undefined,
      Object? categorySortBy = undefined,
    }) {
      return SalesQueryData(
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
        salesByProductData: salesByProductData.or(this.salesByProductData),
        salesByCategoryData: salesByCategoryData.or(this.salesByCategoryData),
        productSortBy: productSortBy.or(this.productSortBy),
        categorySortBy: categorySortBy.or(this.categorySortBy),
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
      ];
}

enum SalesByProductReportSortBy {
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
        return productA.sku.compareTo(productB.sku);
      case SalesByProductReportSortBy.skuDescending:
        return productB.sku.compareTo(productA.sku);
      case SalesByProductReportSortBy.productNameAscending:
        return productA.name.compareTo(productB.name);
      case SalesByProductReportSortBy.productNameDescending:
        return productB.name.compareTo(productA.name);
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
  categoryNameAscending('Category Name Ascending'),
  categoryNameDescending('Category Name Descending'),
  unitsSoldAscending('Units Sold Ascending'),
  unitsSoldDescending('Units Sold Descending'),
  unitsOrderedAscending('Units Ordered Ascending'),
  unitsOrderedDescending('Units Ordered Descending'),
  sellingPriceAscending('Selling Price Ascending'),
  sellingPriceDescending('Selling Price Descending'),
  totalRevenueAscending('Total Revenue Ascending'),
  totalRevenueDescending('Total Revenue Descending'),
  totalOrderCostAscending('Total Order Cost Ascending'),
  totalOrderCostDescending('Total Order Cost Descending'),
  grossProfitAscending('Gross Profit Ascending'),
  grossProfitDescending('Gross Profit Descending'),
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

  int compare(
    (List<(Product, SalesExtras)>, Category) a,
    (List<(Product, SalesExtras)>, Category) b,
  ) {
    late final totalRevenueA = a.totalRevenue;
    late final totalRevenueB = b.totalRevenue;

    late final totalOrderCostA = a.orderCost;
    late final totalOrderCostB = b.orderCost;

    late final totalGrossA = totalRevenueA - totalOrderCostA;
    late final totalGrossB = totalRevenueB - totalOrderCostB;

    switch (this) {
      case SalesByCategoryReportSortBy.categoryNameAscending:
        return a.category.name.compareTo(b.category.name);
      case SalesByCategoryReportSortBy.categoryNameDescending:
        return b.category.name.compareTo(a.category.name);
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
