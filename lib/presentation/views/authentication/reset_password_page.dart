import 'package:easthardware_pms/presentation/bloc/authentication/reset_form/reset_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ResetFormBloc>()
        ..add(ResetFormUsernameChanged(username)),
      child: ColoredBox(
        color: FluentTheme.of(context).micaBackgroundColor,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Spacer(),
                Expanded(child: _ResetPasswordForm()),
                Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm();

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
            _FormHeader(),
            const _UsernameInputSection(),
            const _SecurityQuestionSection(),
            const _AnswerInputSection(),
            const _SubmitSection(),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        HeadingText("Reset Password", textAlign: TextAlign.start),
        GrayText("Verify your identity to reset your password",
            textAlign: TextAlign.start),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _UsernameInputSection extends StatelessWidget {
  const _UsernameInputSection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResetFormBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Username'),
        TextFormBox(
          controller: TextEditingController(text: state.username),
          enabled: false,
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _SecurityQuestionSection extends StatelessWidget {
  const _SecurityQuestionSection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResetFormBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Security Question'),
        if (state.status == ResetFormStatus.loading &&
            state.username.isNotEmpty)
          const Row(
            children: [
              SizedBox(width: 16, height: 16, child: ProgressRing()),
              Spacing.h8,
              BodyText('Loading questions...'),
            ],
          )
        else
          ComboBox<String>(
            placeholder: Text(
              state.questions.isEmpty
                  ? "Enter username first"
                  : "Select a question",
              style: TextStyle(color: Colors.grey[120]),
            ),
            value:
                state.selectedQuestion.isEmpty ? null : state.selectedQuestion,
            items: state.questions
                .map((q) => ComboBoxItem<String>(
                      value: q.question,
                      child: Text(q.question),
                    ))
                .toList(),
            onChanged: state.questions.isNotEmpty
                ? (value) {
                    if (value != null) {
                      context
                          .read<ResetFormBloc>()
                          .add(ResetFormSecurityQuestionSelected(value));
                    }
                  }
                : null,
            isExpanded: true,
          ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _AnswerInputSection extends StatelessWidget {
  const _AnswerInputSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Answer'),
        TextFormBox(
          placeholder: 'Enter your answer',
          onChanged: (value) => context
              .read<ResetFormBloc>()
              .add(ResetFormAnswerChanged(value.trim())),
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class _SubmitSection extends StatelessWidget {
  const _SubmitSection();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetFormBloc, ResetFormState>(
      listener: (context, state) {
        if (state.status == ResetFormStatus.success) {
          context.navigateWithExtra(AppRoutes.newPassword, state.username);
        }
      },
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed:
                    state.status == ResetFormStatus.loading || !state.isValid
                        ? null
                        : () {
                            primaryFocus?.unfocus();
                            context
                                .read<ResetFormBloc>()
                                .add(const ResetFormSubmitted());
                          },
                child: Padding(
                  padding: AppPadding.a8,
                  child: state.status == ResetFormStatus.loading
                      ? const SizedBox(
                          height: 16, width: 16, child: ProgressRing())
                      : const ButtonText("Submit"),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
