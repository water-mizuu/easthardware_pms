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
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  NotificationType _selectedType = NotificationType.info;

  @override
  void initState() {
    super.initState();
    // Load notifications when the page is opened
    context.read<NotificationCubit>().loadNotifications();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create notification form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Notification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Message input
                  InfoLabel(
                    label: 'Message',
                    child: TextBox(
                      controller: _messageController,
                      placeholder: 'Notification message...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Path input
                  InfoLabel(
                    label: 'Path',
                    child: TextBox(
                      controller: _pathController,
                      placeholder: 'e.g., /invoices/123',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Type selection
                  InfoLabel(
                    label: 'Type',
                    child: ComboBox<NotificationType>(
                      value: _selectedType,
                      items: NotificationType.values.map((type) {
                        return ComboBoxItem<NotificationType>(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Create button
                  FilledButton(
                    onPressed: () {
                      if (_messageController.text.isNotEmpty && _pathController.text.isNotEmpty) {
                        context.read<NotificationCubit>().addNotification(
                              title: 'New Notification',
                              type: _selectedType,
                              message: _messageController.text,
                              path: _pathController.text,
                            );
                        _messageController.clear();
                        _pathController.clear();
                      }
                    },
                    child: const Text('Create Notification'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification list header with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Button(
                    onPressed: () {
                      context.read<NotificationCubit>().markAllAsRead();
                    },
                    child: const Text('Mark All as Read'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: () {
                      context.read<NotificationCubit>().deleteAllNotifications();
                    },
                    child: const Text('Delete All'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: () {
                      context.read<NotificationCubit>().loadNotifications();
                    },
                    child: const Text('Refresh'),
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
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];

                    return Card(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon based on notification type
                          _buildNotificationIcon(notification.type),
                          const SizedBox(width: 12),

                          // Notification content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Notification metadata (time + read status)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(notification.time),
                                      style: TextStyle(
                                        color: Colors.grey[130],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Message
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontWeight:
                                        notification.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Path
                                Text(
                                  'Path: ${notification.path}',
                                  style: TextStyle(
                                    color: Colors.grey[130],
                                    fontSize: 12,
                                  ),
                                ),

                                // Notification action buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!notification.isRead)
                                      Button(
                                        onPressed: () {
                                          context
                                              .read<NotificationCubit>()
                                              .markAsRead(notification.id);
                                        },
                                        child: const Text('Mark as Read'),
                                      ),
                                    const SizedBox(width: 8),
                                    Button(
                                      onPressed: () {
                                        context
                                            .read<NotificationCubit>()
                                            .deleteNotification(notification.id);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.info:
        icon = FluentIcons.info;
        color = Colors.blue;
        break;
      case NotificationType.warning:
        icon = FluentIcons.warning;
        color = Colors.yellow;
        break;
      case NotificationType.error:
        icon = FluentIcons.error;
        color = Colors.red;
        break;
      case NotificationType.success:
        icon = FluentIcons.check_mark;
        color = Colors.green;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 24,
    );
  }
}
