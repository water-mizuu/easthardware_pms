import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/security_questions/security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  late final UserFormBloc userFormBloc;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider.value(value: userFormBloc),
    ];
  }

  List<SingleChildWidget> get listeners {
    return [
      BlocListener<UserFormBloc, UserFormState>(
        bloc: userFormBloc,
        listener: (context, state) {
          switch (state.status) {
            case FormStatus.initial:
              break;
            case FormStatus.submitting:
              final id = state.userId;
              if (id == null) {
                if (kDebugMode) {
                  print('Tried to submit a user with no ID.');
                }

                return;
              }
              final user = state.mapStateToUser().copyWith(id: id);
              context.read<UserListBloc>().add(AddUserEvent(user));

              final securityQuestions = state.questions //
                  .map((question) => question.toSecurityQuestion(id))
                  .toList();

              for (final question in securityQuestions) {
                context.read<SecurityQuestionListBloc>().add(AddSecurityQuestionEvent(question));
              }
              final creator = context.read<AuthenticationBloc>().state.user;
              context.read<UserFormBloc>().add(FormSubmittedEvent());
              context.read<UserLogListBloc>().add(AddCreateEvent('User #$id', creator!));
              break;
            case FormStatus.submitted:
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  context.read<UserFormBloc>().add(FormResetEvent());
                }
              });
              // Show success message and navigate back
              context.navigate(AppRoutes.admin.createUser);
              break;
            case FormStatus.error:
              // Show error message
              break;
            default:
              break;
          }
        },
      )
    ];
  }

  @override
  void initState() {
    super.initState();

    userFormBloc = UserFormBloc();
  }

  @override
  void dispose() {
    userFormBloc.close();

    super.dispose();
  }

  Widget buildWidget(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        children: [
          const PageHeader(),
          Expanded(
            child: Form(
              key: userFormBloc.formKey,
              child: Row(
                children: const [
                  UserCredentialsSection(),
                  SecuritySection(),
                ].withSpacing(() => Spacing.h16),
              ),
            ),
          )
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocListener(
        listeners: listeners,
        child: buildWidget(context),
      ),
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
          onPressed: () {
            context.navigate(AppRoutes.admin.users);
          },
        ),
        const DisplayText('Create User'),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save User',
          onPressed: () {
            final userId = context.read<UserListBloc>().state.users.length;

            context.read<UserFormBloc>()
              ..add(UserIdChangedEvent(userId))
              ..add(FormButtonPressedEvent());
          },
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserCredentialsSection extends StatelessWidget {
  const UserCredentialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: AppPadding.a16,
        decoration: const BoxDecoration(color: Colors.white),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SubheadingText('User Information'),
              FirstNameLastNameFields(),
              UsernameField(),
              PasswordField(),
            ].withSpacing(() => Spacing.v16),
          ),
        ),
      ),
    );
  }
}

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: AppPadding.a16,
        decoration: const BoxDecoration(color: Colors.white),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SubheadingText('Account Information'),
              AccessLevelField(),
              SecurityQuestionFields(),
              // Include access level permissions
            ].withSpacing(() => Spacing.v16),
          ),
        ),
      ),
    );
  }
}

class FirstNameLastNameFields extends StatelessWidget with UserFormValidator {
  const FirstNameLastNameFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BodyText('First Name'),
            TextFormBox(
              validator: validateFirstName,
              placeholder: 'First Name',
              onChanged: (value) {
                context.read<UserFormBloc>().add(FirstNameFieldChangedEvent(value));
              },
            ),
          ].withSpacing(() => Spacing.v8),
        )),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BodyText('Last Name'),
            TextFormBox(
              validator: validateLastName,
              placeholder: 'Last Name',
              onChanged: (value) {
                context.read<UserFormBloc>().add(LastNameFieldChangedEvent(value));
              },
            ),
          ].withSpacing(() => Spacing.v8),
        )),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UsernameField extends StatelessWidget with UserFormValidator {
  const UsernameField({super.key});

  @override
  Widget build(BuildContext context) {
    final existingUsernames = context
        .read<UserListBloc>() //
        .state
        .users
        .map((user) => user.username)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Username'),
        TextFormBox(
          validator: (value) => validateUsername(value, existingUsernames),
          placeholder: 'Username',
          onChanged: (value) {
            context.read<UserFormBloc>().add(UsernameFieldChangedEvent(value));
          },
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class PasswordField extends StatelessWidget with UserFormValidator {
  const PasswordField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Password'),
        TextFormBox(
          validator: validatePassword,
          placeholder: 'Password',
          onChanged: (value) {
            context.read<UserFormBloc>().add(PasswordFieldChangedEvent(value));
          },
        ),
        const CaptionText(
          'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.',
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ConfirmPasswordField extends StatelessWidget with UserFormValidator {
  const ConfirmPasswordField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Confirm Password'),
        TextFormBox(
          validator: (value) {
            final password = context.read<UserFormBloc>().state.password;
            return validateConfirmPassword(value, password);
          },
          placeholder: 'Confirm Password',
          onChanged: (value) {
            context.read<UserFormBloc>().add(ConfirmPasswordFieldChangedEvent(value));
          },
        ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class AccessLevelField extends StatelessWidget with UserFormValidator {
  const AccessLevelField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserFormBloc, UserFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BodyText('Access Level'),
            Spacing.v8,
            ComboBox(
              placeholder: const BodyText('Select Access Level'),
              value: state.accessLevel,
              isExpanded: true,
              onChanged: (value) {
                context.read<UserFormBloc>().add(AccessLevelFieldChangedEvent(value!));
              },
              items: AccessLevel.values.map((level) {
                return ComboBoxItem(
                  value: level.name,
                  child: BodyText(level.name.capitalize()),
                );
              }).toList(),
            ),
            if (state.accessLevelErrorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: AppPadding.a4.top),
                child: ErrorText(state.accessLevelErrorMessage!),
              ),
          ],
        );
      },
    );
  }
}

class SecurityQuestionFields extends StatelessWidget with UserFormValidator {
  const SecurityQuestionFields({super.key});

  @override
  Widget build(BuildContext context) {
    final formQuestions = context.read<UserFormBloc>().state.questions;
    return Column(
      children: [
        for (final (index, _) in formQuestions.indexed)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BodyText('Security Question ${index + 1}'),
                    Spacing.v8,
                    AutoSuggestBox.form(
                      validator: (value) {
                        final copy = formQuestions.toList()..removeAt(index);

                        return validateSecurityQuestion(
                          value,
                          copy.map((e) => e.question).toList(),
                          index,
                        );
                      },
                      items: [
                        for (final staticQuestion in SECURITY_QUESTIONS)
                          AutoSuggestBoxItem(
                            label: staticQuestion,
                            value: staticQuestion,
                            onSelected: () {
                              context
                                  .read<UserFormBloc>()
                                  .add(QuestionFieldChangedEvent(staticQuestion, index));
                            },
                          )
                      ],
                      onChanged: (text, reason) {
                        context.read<UserFormBloc>().add(QuestionFieldChangedEvent(text, index));
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Answer'),
                    TextFormBox(
                      validator: (value) => validateSecurityAnswer(value, index),
                      onChanged: (value) {
                        context.read<UserFormBloc>().add(AnswerFieldChangedEvent(value, index));
                      },
                    ),
                  ].withSpacing(() => Spacing.v8),
                ),
              ),
            ].withSpacing(() => Spacing.h16),
          )
      ].withSpacing(() => Spacing.v16),
    );
  }
}
