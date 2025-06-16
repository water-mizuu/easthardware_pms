import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'login_form/login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'login_form/login_form_validator.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _isLoadingStates = {FormStatus.validating, FormStatus.submitting};

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginFormBloc, LoginFormState>(
      listener: (context, state) {
        if (state.formErrors.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Validate the form after the frame is drawn to ensure the UI is updated
            context.read<LoginFormBloc>().formKey.currentState?.validate();

            /// After showing the errors, clear the errors in the state.
            context.read<LoginFormBloc>().add(const LoginFormClearErrors());
          });
        }
      },
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: AppPadding.a32,
          child: Form(
            key: context.select((LoginFormBloc b) => b.formKey),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("assets/icons/app.png", height: 24.0),
                const _FormHeader(),
                const _FormUsernameField(),
                const _FormPasswordField(),
                if (kDebugMode) const _PreserveDebugLogin(),
                const _FormButton(),
                if (kDebugMode)
                  BlocBuilder<AuthenticationBloc, AuthenticationState>(
                    builder: (context, state) {
                      return Text(state.loginAttempts.toString());
                    },
                  )
              ].withSpacing(() => Spacing.v16),
            ),
          ),
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
      children: [
        const HeadingText(
          "Login",
          textAlign: TextAlign.start,
        ),
        const GrayText(
          "Fill in the form below to log in",
          textAlign: TextAlign.start,
        )
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _FormUsernameField extends StatelessWidget with LoginFormValidator {
  const _FormUsernameField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText("Username"),
        BlocBuilder<LoginFormBloc, LoginFormState>(
          buildWhen: (p, c) => p.usernameError != c.usernameError,
          builder: (context, state) => TextFormBox(
            validator: (v) => state.usernameError ?? validateUsername(v),
            onChanged: (value) => context //
                .read<LoginFormBloc>()
                .add(LoginFormUsernameChanged(value)),
          ),
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _FormPasswordField extends StatelessWidget with LoginFormValidator {
  const _FormPasswordField();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Password'),
        BlocBuilder<LoginFormBloc, LoginFormState>(
          buildWhen: (p, c) => p.passwordError != c.passwordError,
          builder: (context, state) => TextFormBox(
            obscureText: true,
            validator: (v) => state.passwordError ?? validatePassword(v),
            onChanged: (value) => context //
                .read<LoginFormBloc>()
                .add(LoginFormPasswordChanged(value)),
          ),
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _FormButton extends StatelessWidget {
  const _FormButton();

  @override
  Widget build(BuildContext context) {
    final status = context.select((LoginFormBloc b) => b.state.status);
    final isLoading = _isLoadingStates.contains(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () {
            if (isLoading) {
              return null;
            }

            return () => context.read<LoginFormBloc>().add(const LoginFormButtonPressed());
          }(),
          child: Padding(
            padding: AppPadding.a8,
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return const SizedBox(
                    height: 16.0,
                    width: 16.0,
                    child: OverflowBox(
                      maxHeight: 28.0,
                      maxWidth: 28.0,
                      child: ProgressRing(strokeWidth: 3.5),
                    ),
                  );
                }
                return const ButtonText("Login") as Widget;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PreserveDebugLogin extends StatefulWidget {
  const _PreserveDebugLogin();

  @override
  State<_PreserveDebugLogin> createState() => _PreserveDebugLoginState();
}

class _PreserveDebugLoginState extends State<_PreserveDebugLogin> {
  late final ValueNotifier<bool> _isLoginPreserved;
  late final SharedPreferencesAsync _sharedPreferences;

  String? _submittedUsername;
  String? _submittedPassword;

  @override
  void initState() {
    super.initState();

    _sharedPreferences = SharedPreferencesAsync();
    _isLoginPreserved = ValueNotifier<bool>(true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /// Load the initial value from shared preferences.
      final preservedUsername = await _sharedPreferences.getString("preserved_username");
      final preservedPassword = await _sharedPreferences.getString("preserved_password");

      if (preservedUsername == null || preservedPassword == null) {
        return;
      }

      if (!mounted) return;
      _submittedUsername = preservedUsername;
      _submittedPassword = preservedPassword;
      context //
          .read<AuthenticationBloc>()
          .add(
            AuthenticationLoginEvent(
              username: preservedUsername,
              password: preservedPassword,
            ),
          );
    });
  }

  @override
  void dispose() {
    _isLoginPreserved.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginFormBloc, LoginFormState>(
      listenWhen: (p, c) => c.status == FormStatus.submitting,
      listener: (context, state) {
        if (state.status == FormStatus.submitting) {
          _submittedUsername = state.username;
          _submittedPassword = state.password;
        }
      },
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.user == null && c.user != null,
        listener: (context, state) {
          assert(
            _submittedUsername == state.user?.username,
            "Submitted username does not match the authenticated user.",
          );
          if (_isLoginPreserved.value) {
            _sharedPreferences.setString("preserved_username", _submittedUsername!);
            _sharedPreferences.setString("preserved_password", _submittedPassword!);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                "(DEBUG) Preserve login: ",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.0),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _isLoginPreserved,
              builder: (context, value, _) {
                return ToggleSwitch(
                  checked: _isLoginPreserved.value,
                  onChanged: (value) {
                    _isLoginPreserved.value = value;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
