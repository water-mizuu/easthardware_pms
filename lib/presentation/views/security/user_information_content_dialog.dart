import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserInformationContentDialog extends StatelessWidget {
  const UserInformationContentDialog({
    super.key,
    required this.currentUser,
    required this.dialogContext,
    required this.user,
  });

  final User currentUser;
  final BuildContext dialogContext;
  final User user;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxHeight: 700, maxWidth: 1000),
      title: DialogTitle(
        currentUser: currentUser,
        dialogContext: dialogContext,
        user: user,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BasicInformationDetails(user: user),
          Spacing.v16,
          AccountStatusDetails(user: user),
        ],
      ),
    );
  }
}

class DialogTitle extends StatelessWidget {
  const DialogTitle({
    super.key,
    required this.currentUser,
    required this.dialogContext,
    required this.user,
  });

  final User currentUser;
  final BuildContext dialogContext;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('User Details', style: TextStyles.title),
        const Spacer(),
        Row(
          children: [
            if ( //
                currentUser.accessLevel == AccessLevel.administrator && currentUser.id != user.id //
                )
              TextButton(
                'Make User Inactive',
                onPressed: () {
                  context.read<UserListBloc>().add(ArchiveUserEvent(user));
                  context.read<UserLogListBloc>().add(AddArchiveEvent('User #${user.id}', user));
                  Navigator.of(dialogContext).pop();
                },
              ),
            if (currentUser.id == user.id) ...[
              Spacing.h8,
              TextButton(
                'Edit User',
                onPressed: () {
                  context.navigateWithExtra(AppRoutes.admin.editUser, user);
                  context.read<UserLogListBloc>().add(AddArchiveEvent('User #${user.id}', user));
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
            Spacing.h8,
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Icon(FluentIcons.chrome_close),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
        Spacing.h4,
      ],
    );
  }
}

class BasicInformationDetails extends StatelessWidget {
  const BasicInformationDetails({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Basic Information', style: TextStyles.title),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('First Name', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(child: Text(user.firstName, style: TextStyles.body)),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Last Name', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(child: Text(user.lastName, style: TextStyles.body)),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Username', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(child: Text(user.username, style: TextStyles.body)),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Access Level', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(child: Text(user.accessLevel.name.toUpperCase(), style: TextStyles.body)),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }
}

class AccountStatusDetails extends StatelessWidget {
  const AccountStatusDetails({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    final creationDate = DateFormat.yMMMMd().format(DateTime.parse(user.creationDate));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Account Status', style: TextStyles.title),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Creation Date', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(child: Text(creationDate, style: TextStyles.body)),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Login Status', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                user.loginStatus == 1 ? 'Online' : 'Offline',
                style: TextStyles.body,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(child: Text('Archive Status', style: TextStyles.onSurfaceVariant)),
            const Spacer(),
            Expanded(
              child: Text(
                user.archiveStatus == 1 ? 'Archived' : 'Active',
                style: TextStyles.body,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }
}
