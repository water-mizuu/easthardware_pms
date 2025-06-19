import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
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
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class CreateProductPage extends StatelessWidget {
  const CreateProductPage({super.key});

  void _handleFormSubmit(BuildContext context, ProductFormState state) {
    context.read<ProductListBloc>().add(
          AddProductEvent(
            category: Category(name: state.categoryName),
            product: state.toProduct(),
            units: [
              for (final unit in state.secondaryUnits)
                if (unit.name.isNotEmpty) unit.toUnit()
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [BlocProvider(create: (_) => ProductFormBloc())],
      builder: (context, child) {
        return MultiBlocListener(
          listeners: [
            BlocListener<ProductFormBloc, ProductFormState>(
              bloc: context.read<ProductFormBloc>(),
              listenWhen: (p, c) => c.formStatus == FormStatus.error,
              listener: (context, state) {
                assert(state.errorMessage != null, "Error message must not be empty.");

                if (kDebugMode) {
                  printBoxed(
                    "Error occurred while submitting the form: "
                        "${state.errorMessage}\n${StackTrace.current}",
                    "ProductFormBloc",
                  );
                }

                showNotification(
                  title: 'Error',
                  message: state.errorMessage ?? 'An error occurred while submitting the form.',
                  severity: InfoBarSeverity.error,
                );
              },
            ),
            BlocListener<UserLogListBloc, UserLogListState>(
              bloc: context.read<UserLogListBloc>(),
              listenWhen: (p, c) => c.status == DataStatus.error,
              listener: (context, state) {
                assert(state.errorMessage != null, "Error message must not be empty.");

                if (kDebugMode) {
                  printBoxed(
                    "Error occurred while submitting the form: "
                        "${state.errorMessage}\n${StackTrace.current}",
                    "ProductFormBloc",
                  );
                }

                showNotification(
                  title: 'Error',
                  message: state.errorMessage ?? 'An error occurred while submitting the form.',
                  severity: InfoBarSeverity.error,
                );
              },
            ),
            BlocListener<UnitListBloc, UnitListState>(
              bloc: context.read<UnitListBloc>(),
              listenWhen: (p, c) => c.status == DataStatus.error,
              listener: (context, state) {
                assert(state.errorMessage != null, "Error message must not be empty.");

                if (kDebugMode) {
                  printBoxed(
                    "Error occurred while submitting the form: "
                        "${state.errorMessage}\n${StackTrace.current}",
                    "ProductFormBloc",
                  );
                }

                showNotification(
                  title: 'Error',
                  message: state.errorMessage ?? 'An error occurred while submitting the form.',
                  severity: InfoBarSeverity.error,
                );
              },
            ),
            BlocListener<ProductListBloc, ProductListState>(
              listenWhen: (previous, current) =>
                  previous.latest != current.latest && //
                  current.latest != null,
              listener: (context, state) {
                final latest = state.latest!;
                final authState = context.read<AuthenticationBloc>().state;

                // Update Category
                context.read<CategoryListBloc>().add(const ReloadCategoriesEvent());
                // Update Secondary Units
                context.read<UnitListBloc>().add(const ReloadUnitsEvent());
                context
                    .read<UserLogListBloc>()
                    .add(AddCreateEvent('Product ${latest.id}', authState.user!));
                context.read<ProductFormBloc>().add(FormSubmittedEvent());
              },
            )
          ],
          child: BlocListener<ProductFormBloc, ProductFormState>(
            listener: (context, state) {
              switch (state.formStatus) {
                case FormStatus.submitting:
                  _handleFormSubmit(context, state);
                  break;
                case FormStatus.submitted:

                  /// Reset the form
                  context.read<ProductFormBloc>().add(FormResetEvent());

                  /// Navigate to the inventory page after successful submission.
                  context.navigate(AppRoutes.admin.inventory);
                  break;
                default:
                  break;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: AppPadding.panePadding.copyWith(bottom: 0.0),
                  child: const PageHeader(),
                ),
                const Expanded(child: ProductInformationFormContent()),
              ],
            ),
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
        const DisplayText('Create Product'),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save Product',
          onPressed: () {
            final creatorId = context.read<AuthenticationBloc>().state.user!.id!;
            final productId = context.read<ProductListBloc>().state.allProducts.length;
            printBoxed(productId);
            context.read<ProductFormBloc>().add(
                  FormButtonPressedEvent(productId: productId, creatorId: creatorId),
                );
          },
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}
