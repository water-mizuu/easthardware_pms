import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/sales_query_data.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';

typedef SalesByCategoryDatum = (List<(Product, SalesExtras)>, Category);

extension SalesByCategoryDatumShortcuts on SalesByCategoryDatum {
  List<Product> get products => $1.map((e) => e.$1).toList();
  Category get category => $2;
  List<SalesExtras> get extras => $1.map((e) => e.$2).toList();

  double get salePrice => products.map((p) => p.salePrice).sum();
  double get orderCost => products.map((p) => p.orderCost).sum();

  double get unitsSold => extras.map((e) => e.unitsSold).sum();
  double get unitsOrdered => extras.map((e) => e.unitsOrdered).sum();
  double get totalRevenue => $1.map((pair) => pair.$1.salePrice * pair.$2.unitsSold).sum();
  double get totalCost => $1.map((pair) => pair.$1.orderCost * pair.$2.unitsOrdered).sum();
  double get grossProfit => totalRevenue - totalCost;
}
