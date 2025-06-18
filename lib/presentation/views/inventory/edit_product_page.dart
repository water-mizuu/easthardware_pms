import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_form/product_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/inventory/product_information_form_content.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class EditProductPage extends StatelessWidget {
  const EditProductPage({required this.product, super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final unitState = context.read<UnitListBloc>().state;
            final secondaryUnits = unitState.units //
                .where((u) => u.productId == product.id)
                .toList();
            return ProductFormBloc.fromProduct(product, secondaryUnits);
          },
        ),
      ],
      builder: (context, _) {
        return MultiBlocListener(
          listeners: [
            BlocListener<UnitListBloc, UnitListState>(
              listenWhen: (p, c) => p.units != c.units,
              listener: (context, state) {
                assert(product.id != null, 'Product ID must not be null');

                final productFormBloc = context.read<ProductFormBloc>();
                final allSecondaryUnits = state.units;
                final unitsOfThisProduct = allSecondaryUnits //
                    .where((u) => u.productId == product.id)
                    .toList();
                if (kDebugMode) {
                  printBoxed(
                    unitsOfThisProduct.map((u) => u.toMap()).join("\n").wrap,
                    'Units of Product #${product.id}',
                  );
                }

                productFormBloc.add(ProductLoadedEvent(product, unitsOfThisProduct));
              },
            ),
            BlocListener<ProductFormBloc, ProductFormState>(
              listenWhen: (p, c) => p.formStatus != c.formStatus,
              listener: (context, state) {
                switch (state.formStatus) {
                  case FormStatus.initial:
                    printBoxed(state.productId, 'EditProduct - ProductId');
                    break;
                  case FormStatus.submitting:
                    final info = [
                      '- ${state.productId}',
                      state.name,
                      state.categoryId,
                      state.categoryName,
                      state.description,
                      state.mainUnit,
                      state.archivedStatus,
                      state.secondaryUnits //
                          .map((u) => u.toUnit().toMap())
                          .toList(),
                      state.deadStockThreshold,
                      state.criticalLevel,
                      state.fastMovingThreshold
                    ].map((e) => e.toString()).join('\n -');
                    if (kDebugMode) {
                      printBoxed(
                          'Submitting Product Form: ${info.toString().wrap}', 'EditProductPage');
                    }
                    context.read<ProductListBloc>().add(
                          UpdateProductEvent(
                            state.toProduct().copyWith(id: state.productId),
                            Category(name: state.categoryName),
                            [
                              ...state.secondaryUnits //
                                  .where((u) => u.name.value.isNotEmpty)
                                  .map((u) => u.toUnit()),
                            ],
                          ),
                        );

                  case FormStatus.submitted:
                    Future.delayed(Duration.zero, () {
                      if (context.mounted) {
                        context.navigate(AppRoutes.admin.inventory);
                      }
                    });
                  case FormStatus.error:
                    if (kDebugMode) {
                      print("Error");
                    }
                    break;
                  default:
                    break;
                }
              },
            ),
            BlocListener<ProductListBloc, ProductListState>(
              listenWhen: (p, c) => p.latest != c.latest && c.latest != null,
              listener: (context, state) {
                final user = context.read<AuthenticationBloc>().state.user!;
                context //
                    .read<UserLogListBloc>()
                    .add(AddUpdateEvent('Product #${state.latest!.id}', user));
                context.read<CategoryListBloc>().add(const ReloadCategoriesEvent());
                context.read<UnitListBloc>().add(const ReloadUnitsEvent());
                if (kDebugMode) {
                  printBoxed(
                    'Product #${state.latest!.id} updated by ${user.username}',
                    'EditProductPage',
                  );
                }
                context.read<ProductFormBloc>().add(FormSubmittedEvent());
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: AppPadding.panePadding.top,
                  left: AppPadding.panePadding.left,
                  right: AppPadding.panePadding.right,
                ),
                child: const PageHeader(),
              ),
              const Expanded(child: ProductInformationFormContent()),
            ].withSpacing(() => Spacing.v16),
          ),
        );
      },
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.inventory),
        ),
        const DisplayText('Edit Product'),
        const Spacer(flex: 1),
        TextButton('Archive Product', onPressed: () {
          // Set Status to Inactive
          final previous = context.read<ProductFormBloc>().state.archivedStatus;
          final current = previous == 0 ? 1 : 0;
          context.read<ProductFormBloc>().add(ProductStatusChangedEvent(current));
          if (kDebugMode) {
            printBoxed(
              'Product Status changed from $previous to $current',
              'EditProductPage',
            );
          }

          // Update Product
          final productId = context.read<ProductFormBloc>().state.productId!;
          final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
          context
            ..read<UserLogListBloc>().add(AddArchiveEvent(
              'Product #${context.read<ProductFormBloc>().state.productId}',
              context.read<AuthenticationBloc>().state.user!,
            ))
            ..read<ProductFormBloc>().add(FormButtonPressedEvent(
              productId: productId,
              creatorId: creatorId,
            ));
        }),
        TextButtonFilled('Update Product', onPressed: () {
          final state = context.read<ProductFormBloc>().state;
          final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
          context //
              .read<ProductFormBloc>()
              .add(FormButtonPressedEvent(
                productId: state.productId!,
                creatorId: creatorId,
              ));
        })
      ].withSpacing(() => Spacing.h16),
    );
  }
}
