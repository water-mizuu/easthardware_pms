import 'dart:async';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/ui/badges.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:intl/intl.dart';

class NotificationsPanePage extends StatefulWidget {
  const NotificationsPanePage({super.key});

  @override
  State<NotificationsPanePage> createState() => _NotificationsPanePageState();
}

class _NotificationsPanePageState extends State<NotificationsPanePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Notifications',
                style: TextStyles.title,
              ),
              Row(
                children: [
                  TextButton(
                    "Mark All as Read",
                    onPressed: () {
                      unawaited(context.read<NotificationCubit>().markAllAsRead());
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    'Clear All',
                    onPressed: () {
                      unawaited(context.read<NotificationCubit>().deleteAllNotifications());
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Notification list
          Expanded(
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state.notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications yet'),
                  );
                }

                return ListView.builder(
                  itemCount: state.notifications.length,
                  itemBuilder: (itemBuilder, index) {
                    final notification = state.notifications[index];

                    return HoverButton(
                      onPressed: () {},
                      builder: (context, states) {
                        return Card(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.only(bottom: 4),
                          backgroundColor: states.isHovered
                              ? FluentTheme.of(context).resources.cardBackgroundFillColorSecondary
                              : null,
                          child: MouseRegion(
                            onEnter: (_) {
                              if (!notification.isRead) {
                                unawaited(
                                    context.read<NotificationCubit>().markAsRead(notification.id));
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon based on path
                                _buildNotificationIcon(notification.path.split(',').first.trim()),
                                const SizedBox(width: 12),

                                // Notification content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(notification.title, style: TextStyles.strong),
                                          Row(
                                            children: [
                                              Text(
                                                DateFormat('hh:mm a').format(notification.time),
                                                style: TextStyles.onSurfaceVariant
                                                    .merge(TextStyles.caption),
                                              ),
                                              const SizedBox(width: 8),
                                              if (!notification.isRead) Badges.normal(''),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon:
                                                    const Icon(FluentIcons.chrome_close, size: 12),
                                                onPressed: () {
                                                  unawaited(itemBuilder
                                                      .read<NotificationCubit>()
                                                      .deleteNotification(notification.id));
                                                },
                                              ),
                                              if ( //
                                                  _mapPathToRoute(notification. //
                                                          path
                                                          .split(',')
                                                          .first
                                                          .trim()) !=
                                                      null //
                                                  ) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(FluentIcons.chevron_right_med,
                                                      size: 12),
                                                  onPressed: () {
                                                    final path =
                                                        notification.path.split(',').first.trim();
                                                    final id = int.tryParse(
                                                        notification.path.split(',').last);
                                                    final route = _mapPathToRoute(path);
                                                    if (route != null) {
                                                      final extra = _mapPathToExtra(path, id);
                                                      context.navigateWithExtra(route, extra);
                                                    } else {}
                                                  },
                                                ),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Message
                                      Text(
                                        notification.message,
                                        style:
                                            TextStyles.onSurfaceVariant.merge(TextStyles.caption),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppRoute? _mapPathToRoute(String path) {
    final level = context.read<AuthenticationBloc>().state.user!.accessLevel;
    if (level == AccessLevel.administrator) {
      switch (path) {
        case '/admin/create/restock_order':
          return AppRoutes.admin.createRestockOrder.withProduct;
        case '/admin/edit/product':
          return AppRoutes.admin.editProduct;
        case '/admin/edit/invoice':
          return AppRoutes.admin.editInvoice;
        case '/admin/edit/restock_order':
          return AppRoutes.admin.editRestockOrder;
        case '/admin/edit/expense_order':
          return AppRoutes.admin.editExpenseOrder;
        case 'user':
        default:
          return null;
      }
    } else {
      switch (path) {
        case '/admin/edit/invoice':
          return AppRoutes.admin.editInvoice;
        case '/admin/edit/product':
        case '/admin/create/restock_order':
        case '/admin/edit/restock_order':
        case '/admin/edit/expense_order':
        case 'user':
        default:
          return null;
      }
    }
  }

  dynamic _mapPathToExtra(String path, int? id) {
    if (id == null) return null;
    switch (path) {
      case '/admin/create/restock_order':
      case '/admin/edit/product':
        return context
            .read<ProductListBloc>()
            .state
            .allProducts
            .firstWhere((product) => product.id == id);
      case '/admin/edit/invoice':
        return context
            .read<InvoiceListBloc>()
            .state
            .invoices
            .firstWhere((invoice) => invoice.id == id);
      case '/admin/edit/restock_order':
      case '/admin/edit/expense_order':
        return context //
            .read<OrderListBloc>()
            .state
            .allOrderItems
            .firstWhere((order) => order.id == id);
      case 'user':
      default:
        return null;
    }
  }

  Widget _buildNotificationIcon(String path) {
    IconData icon;

    switch (path) {
      case '/admin/create/restock_order':
        icon = FluentIcons.product_warning;
        break;
      case '/admin/edit/product':
        icon = FluentIcons.product_release;
        break;
      case '/admin/edit/invoice':
        icon = FluentIcons.text_document_edit;
        break;
      case '/admin/edit/restock_order':
        icon = FluentIcons.text_document_edit;
        break;
      case '/admin/edit/expense_order':
        icon = FluentIcons.text_document_edit;
        break;
      case 'user':
        icon = FluentIcons.contact;
        break;
      default:
        icon = FluentIcons.ringer;
        break;
    }
    return Icon(icon, size: 16);
  }
}
