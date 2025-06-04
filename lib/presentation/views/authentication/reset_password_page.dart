import 'package:easthardware_pms/presentation/bloc/authentication/'
    'reset_form/reset_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.username});

  final String username;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  void initState() {
    super.initState();

    context
        .read<ResetFormBloc>()
        .add(ResetFormUsernameChanged(widget.username));
  }

  @override
  void didUpdateWidget(ResetPasswordPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.username != widget.username) {
      context
          .read<ResetFormBloc>()
          .add(ResetFormUsernameChanged(widget.username));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).micaBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FormHeader(),
                Spacing.h12,
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UsernameInputSection(),
                    SecurityQuestionSection(),
                    AnswerInputSection(),
                    SubmitSection(),
                  ],
                ),
              ],
            ),
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
          "Reset Password",
          style: FluentTheme.of(context).typography.title,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          "Verify your identity to reset your password",
          style: FluentTheme.of(context)
              .typography
              .body
              ?.copyWith(color: Colors.grey[170]),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class UsernameInputSection extends StatelessWidget {
  const UsernameInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetFormBloc, ResetFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Username'),
            const SizedBox(height: 8),
            TextBox(
              controller: TextEditingController(text: state.username),
              enabled: false,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class SecurityQuestionSection extends StatelessWidget {
  const SecurityQuestionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResetFormBloc>().state;
    //
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Security Question'),
        const SizedBox(height: 8),
        if (state.status == ResetFormStatus.loading &&
            state.username.isNotEmpty)
          const Row(
            children: [
              SizedBox(width: 16, height: 16, child: ProgressRing()),
              Spacing.h8,
              Text('Loading questions...'),
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
            items: [
              for (final q in state.questions)
                ComboBoxItem<String>(
                  value: q.question,
                  child: Text(q.question),
                ),
            ],
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
        const SizedBox(height: 16),
      ],
    );
  }
}

class AnswerInputSection extends StatelessWidget {
  const AnswerInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetFormBloc, ResetFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Answer'),
            const SizedBox(height: 8),
            TextBox(
              placeholder: 'Enter your answer',
              onChanged: (value) {
                context
                    .read<ResetFormBloc>()
                    .add(ResetFormAnswerChanged(value.trim()));
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
    return BlocListener<ResetFormBloc, ResetFormState>(
      listener: (context, state) {
        if (state.status == ResetFormStatus.success) {
          context.navigateWithExtra(AppRoutes.newPassword, state.username);
        } else if (state.status == ResetFormStatus.error &&
            state.errorMessage.isNotEmpty) {}
      },
      child: BlocBuilder<ResetFormBloc, ResetFormState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
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
                  padding: AppPadding.a4,
                  child: state.status == ResetFormStatus.loading
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
