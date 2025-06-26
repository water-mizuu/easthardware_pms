import 'package:easthardware_pms/presentation/bloc/authentication/new_password_form/new_password_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_bloc/flutter_bloc.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key, required this.username});

  final String username;

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  @override
  void initState() {
    super.initState();
    context.read<NewPasswordFormBloc>().add(NewPasswordFormReset(widget.username));
  }

  @override
  void didUpdateWidget(NewPasswordPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      context.read<NewPasswordFormBloc>().add(NewPasswordFormReset(widget.username));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).micaBackgroundColor,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Spacer(),
              Expanded(child: _NewPasswordForm()),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewPasswordForm extends StatelessWidget {
  const _NewPasswordForm();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: AppPadding.a32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("assets/icons/app.png", height: 24.0),
            const _FormHeader(),
            const NewPasswordInputSection(),
            const ConfirmPasswordInputSection(),
            const SubmitSection(),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        HeadingText("New Password", textAlign: TextAlign.start),
        GrayText("Fill in the form below to update your password", textAlign: TextAlign.start),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class NewPasswordInputSection extends StatefulWidget {
  const NewPasswordInputSection({super.key});

  @override
  State<NewPasswordInputSection> createState() => _NewPasswordInputSectionState();
}

class _NewPasswordInputSectionState extends State<NewPasswordInputSection> {
  var obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('New Password'),
        TextFormBox(
          placeholder: 'Enter new password',
          obscureText: obscureText,
          suffix: IconButton(
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => obscureText = !obscureText),
          ),
          onChanged: (value) {
            context.read<NewPasswordFormBloc>().add(NewPasswordChanged(value.trim()));
          },
        ),
        const CaptionText(
          'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.',
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ConfirmPasswordInputSection extends StatefulWidget {
  const ConfirmPasswordInputSection({super.key});

  @override
  State<ConfirmPasswordInputSection> createState() => _ConfirmPasswordInputSectionState();
}

class _ConfirmPasswordInputSectionState extends State<ConfirmPasswordInputSection> {
  var obscureText = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewPasswordFormBloc, NewPasswordFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BodyText('Confirm Password'),
            TextFormBox(
              placeholder: 'Confirm password',
              obscureText: obscureText,
              suffix: IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => obscureText = !obscureText),
              ),
              onChanged: (value) {
                context.read<NewPasswordFormBloc>().add(ConfirmPasswordChanged(value.trim()));
              },
            ),
          ].withSpacing(() => Spacing.v8),
        );
      },
    );
  }
}

class SubmitSection extends StatelessWidget {
  const SubmitSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewPasswordFormBloc, NewPasswordFormState>(
      listener: (context, state) {
        if (state.status == FormStatus.success) {
          context.navigate(AppRoutes.login);
        }
      },
      child: BlocBuilder<NewPasswordFormBloc, NewPasswordFormState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: state.status == FormStatus.loading || !state.isValid
                      ? null
                      : () {
                          primaryFocus?.unfocus();
                          context.read<NewPasswordFormBloc>().add(const NewPasswordFormSubmitted());

                          final username = context.read<NewPasswordFormBloc>().state.username;
                          final user = context
                              .read<UserListBloc>()
                              .state
                              .users
                              .firstWhere((u) => u.username == username);

                          context //
                              .read<UserLogListBloc>()
                              .add(AddUpdateEvent('password', user));
                        },
                  child: Padding(
                    padding: AppPadding.a8,
                    child: state.status == FormStatus.loading
                        ? const SizedBox(height: 16, width: 16, child: ProgressRing())
                        : const ButtonText("Submit"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
