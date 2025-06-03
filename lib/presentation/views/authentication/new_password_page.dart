import 'package:easthardware_pms/presentation/bloc/authentication/new_password_form/new_password_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_bloc/flutter_bloc.dart';

class NewPasswordPage extends StatelessWidget {
  const NewPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).micaBackgroundColor,
      child: const Center(
        child: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FormHeader(),
              NewPasswordInputSection(),
              ConfirmPasswordInputSection(),
              SubmitSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class FormHeader extends StatelessWidget {
  const FormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "New Password",
          style: FluentTheme.of(context).typography.title,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          "Fill in the form below to update your password",
          style: FluentTheme.of(context).typography.body?.copyWith(
                color: Colors.grey[170],
              ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 16),
      ],
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
    final (_) = context.watch<NewPasswordFormBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('New Password'),
        const SizedBox(height: 8),
        TextBox(
          placeholder: 'Enter new password',
          obscureText: obscureText,
          suffix: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
          ),
          onChanged: (value) {
            context.read<NewPasswordFormBloc>().add(NewPasswordChanged(value.trim()));
          },
        ),
        const SizedBox(height: 16),
      ],
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
            const Text('Confirm Password'),
            const SizedBox(height: 8),
            TextBox(
              placeholder: 'Confirm password',
              obscureText: obscureText,
              suffix: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    obscureText = !obscureText;
                  });
                },
              ),
              onChanged: (value) {
                context.read<NewPasswordFormBloc>().add(ConfirmPasswordChanged(value.trim()));
              },
            ),
            const SizedBox(height: 16),
          ],
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
        } else if (state.status == FormStatus.error && state.errorMessage.isNotEmpty) {
          // Handle error - show a dialog or snackbar
        }
      },
      child: BlocBuilder<NewPasswordFormBloc, NewPasswordFormState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: state.status == FormStatus.loading || !state.isValid
                    ? null
                    : () {
                        primaryFocus?.unfocus();
                        context.read<NewPasswordFormBloc>().add(const NewPasswordFormSubmitted());
                      },
                child: Padding(
                  padding: AppPadding.a4,
                  child: state.status == FormStatus.loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: ProgressRing(),
                        )
                      : Text(
                          "Submit",
                          style: FluentTheme.of(context)
                              .typography
                              .bodyLarge!
                              .copyWith(color: const Color(0xFFFFFFFF)),
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
