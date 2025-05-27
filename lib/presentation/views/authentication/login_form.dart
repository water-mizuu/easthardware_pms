import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/login_form_validator.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: AppPadding.a32,
        child: Builder(builder: (context) {
          var formKey = context.read<LoginFormBloc>().formKey;
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("assets/icons/app.png", height: 24.0),
                _FormHeader(),
                _FormUsernameField(),
                _FormPasswordField(),
                _FormButton(),
              ].withSpacing(() => Spacing.v16),
            ),
          );
        }),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeadingText(
            "Login",
            textAlign: TextAlign.start,
          ),
          const GrayText(
            "Fill in the form below to log in",
            textAlign: TextAlign.start,
          )
        ].withSpacing(() => Spacing.v8));
  }
}

class _FormUsernameField extends StatelessWidget with LoginFormValidator {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText("Username"),
        TextFormBox(
          validator: validateUsername,
          onChanged: (value) => context.read<LoginFormBloc>().add(LoginFormUsernameChanged(value)),
        )
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _FormPasswordField extends StatelessWidget with LoginFormValidator {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Password'),
        TextFormBox(
          obscureText: true,
          validator: validatePassword,
          onChanged: (value) {
            context.read<LoginFormBloc>().add(LoginFormPasswordChanged(value));
          },
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _FormButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AuthenticationBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: state.status != AuthenticationStatus.loading
              ? () => context.read<LoginFormBloc>().add(LoginFormButtonPressed())
              : null,
          child: const Padding(
            padding: AppPadding.a8,
            child: ButtonText("Login"),
          ),
        ),
      ],
    );
  }
}
