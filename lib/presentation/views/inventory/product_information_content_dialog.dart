import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/utils/user.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductInformationContentDialog extends StatelessWidget {
  const ProductInformationContentDialog({
    super.key,
    required this.accessLevel,
    required this.dialogContext,
    required this.product,
  });

  final AccessLevel accessLevel;
  final BuildContext dialogContext;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxHeight: 700, maxWidth: 1000),
      title: DialogTitle(accessLevel: accessLevel, dialogContext: dialogContext, product: product),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BasicInformationDetails(product: product),
          Spacing.v16,
          SaleInformationDetails(product: product),
          Spacing.v16,
          StockKeepingInformationDetails(product: product),
        ],
      ),
    );
  }
}

class SaleInformationDetails extends StatelessWidget {
  const SaleInformationDetails({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sale Information', style: TextStyles.title),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text(
                'Sale Price',
                style: TextStyles.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                product.salePrice.toStringAsFixed(2),
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text(
                'Order Cost',
                style: TextStyles.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                product.orderCost.toStringAsFixed(2),
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }
}

class DialogTitle extends StatelessWidget {
  const DialogTitle({
    super.key,
    required this.accessLevel,
    required this.dialogContext,
    required this.product,
  });

  final AccessLevel accessLevel;
  final BuildContext dialogContext;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Product Details', style: TextStyles.title),
        const Spacer(),
        Row(
          children: [
            if (accessLevel.isAdministrator) ...[
              Button(
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(FluentIcons.edit),
                      Spacing.h12,
                      Text('Edit Product', style: TextStyles.body),
                    ],
                  ),
                ),
                onPressed: () {
                  context.navigateWithExtra(AppRoutes.admin.editProduct, product);
                  Navigator.of(dialogContext).pop();
                },
              ),
              Spacing.h8,
            ],
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Icon(FluentIcons.chrome_close),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            )
          ],
        ),
        Spacing.h4,
      ],
    );
  }
}

class StockKeepingInformationDetails extends StatelessWidget {
  const StockKeepingInformationDetails({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Stock Keeping Information', style: TextStyles.title),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text(
                'Reorder Level',
                style: TextStyles.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                product.reorderPoint.toString(),
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text('Reorder Delay', style: TextStyles.onSurfaceVariant),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                '${product.minReorderDelay} days - ${product.maxReorderDelay} days',
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text(
                'Fast Moving Threshold',
                style: TextStyles.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                product.fastMovingStockThreshold.toString(),
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: Text('Dead Stock Threshold', style: TextStyles.onSurfaceVariant),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                product.deadStockThreshold.toString(),
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }
}

class BasicInformationDetails extends StatelessWidget {
  const BasicInformationDetails({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    final units = context
        .select((UnitListBloc b) => b.state.units)
        .where((unit) => unit.productId == product.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Basic Information', style: TextStyles.title),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Product Name', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                product.name,
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('SKU', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                product.sku,
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Category', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                product.categoryName ?? 'Uncategorized',
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Description', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              flex: 2,
              child: Text(
                product.description ?? 'No description provided',
                style: TextStyles.onSurface,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            const Spacer(),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Quantity', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                '${product.quantity} ${product.mainUnit}(s)${units.isNotEmpty ? ' ${units.map((u) => '${product.quantity * (u.unitQuantity / u.mainQuantity)} ${u.name}(s)').join(', ')}' : ''}',
                style: TextStyles.onSurface,
                textAlign: TextAlign.start,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }
}
