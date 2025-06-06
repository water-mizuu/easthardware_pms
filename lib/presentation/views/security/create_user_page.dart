import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/security_questions/'
    'security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/success_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scroll_animator/scroll_animator.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  late final UserFormBloc userFormBloc;
  late final AnimatedScrollController _scrollController;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider.value(value: userFormBloc),
    ];
  }

  List<SingleChildWidget> get listeners {
    return [
      BlocListener<UserFormBloc, UserFormState>(
        bloc: userFormBloc,
        listener: (context, state) async {
          switch (state.status) {
            case FormStatus.initial:
              break;
            case FormStatus.submitting:
              final id = state.userId;
              if (id == null) {
                if (kDebugMode) {
                  print('Tried to submit a user with no ID.');
                }

                break;
              }

              final creator = context.read<AuthenticationBloc>().state.user;
              final createdUser = state.mapStateToUser().copyWith(id: id);

              final securityQuestions = state.questions //
                  .map((question) => question.toSecurityQuestion(id))
                  .toList();

              for (final question in securityQuestions) {
                context.read<SecurityQuestionListBloc>().add(AddSecurityQuestionEvent(question));
              }
              context.read<UserListBloc>().add(AddUserEvent(createdUser));
              context.read<UserLogListBloc>().add(AddCreateEvent('User #$id', creator!));

              /// This makes the form status be submitted.
              context.read<UserFormBloc>().add(FormResetEvent());

              // Show success message and navigate back
              await context.showSuccessDialog(
                title: 'User Created',
                body: 'The user \'${createdUser.username}\' has been successfully created.',
              );
              if (!context.mounted) break;
              context.navigate(AppRoutes.admin.users);

              break;
            case FormStatus.error:
              if (kDebugMode) {
                print('Error while submitting user form: ${state.accessLevelErrorMessage}');
              }
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
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void dispose() {
    userFormBloc.close();
    _scrollController.dispose();

    super.dispose();
  }

  Widget buildWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: AppPadding.panePadding.copyWith(bottom: 0.0),
          child: const PageHeader(),
        ),
        Expanded(
          child: Form(
            key: userFormBloc.formKey,
            child: LayoutMode.builder((context, mode) {
              switch (mode) {
                case LayoutMode.wide:
                  return Padding(
                    padding: AppPadding.panePadding.copyWith(top: 0.0),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: UserCredentialsSection()),
                        Spacing.h16,
                        Expanded(child: SecuritySection()),
                      ],
                    ),
                  );
                case LayoutMode.constrained:
                case LayoutMode.compact:
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: AppPadding.panePadding.copyWith(top: 0.0),
                      child: const Column(
                        children: [
                          UserCredentialsSection(),
                          Spacing.v16,
                          SecuritySection(),
                        ],
                      ),
                    ),
                  );
              }
            }),
          ),
        )
      ].withSpacing(() => Spacing.v16),
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
        const HeadingText('Create User'),
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
    return Container(
      padding: AppPadding.a16,
      decoration: const BoxDecoration(color: Colors.white),
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SubheadingText('User Information'),
            FirstNameLastNameFields(),
            UsernameField(),
            PasswordField(),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.a16,
      decoration: const BoxDecoration(color: Colors.white),
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SubheadingText('Account Information'),
            AccessLevelField(),
            SecurityQuestionFields(),
            // Include access level permissions
          ].withSpacing(() => Spacing.v16),
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
            mainAxisSize: MainAxisSize.min,
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
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
          ),
        ),
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
      mainAxisSize: MainAxisSize.min,
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

class PasswordField extends StatefulWidget {
  const PasswordField({super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> with UserFormValidator {
  late final ValueNotifier<bool> _isObscuredNotifier;

  @override
  void initState() {
    super.initState();

    _isObscuredNotifier = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _isObscuredNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Password'),
        ValueListenableBuilder(
          valueListenable: _isObscuredNotifier,
          builder: (context, isObscured, _) => TextFormBox(
            validator: validatePassword,
            placeholder: 'Password',
            obscureText: isObscured,
            suffix: Consumer<UserFormBloc>(
              builder: (context, bloc, _) {
                final hasContent = bloc.state.password.isNotEmpty;
                if (!hasContent) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => _isObscuredNotifier.value = !isObscured,
                );
              },
            ),
            onChanged: (value) {
              context.read<UserFormBloc>().add(PasswordFieldChangedEvent(value));
            },
          ),
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
      mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
    final formQuestions = context.select((UserFormBloc b) => b.state.questions);
    final remainingStaticQuestions = SECURITY_QUESTIONS //
        .where((question) => !formQuestions.any((e) => e.question == question))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, _) in formQuestions.indexed)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BodyText('Security Question ${index + 1}'),
                  AutoSuggestBox.form(
                    placeholder: "Select or enter question ${index + 1}",
                    validator: (value) {
                      final copy = formQuestions.toList()..removeAt(index);

                      return validateSecurityQuestion(
                        value,
                        copy.map((e) => e.question).toList(),
                        index,
                      );
                    },
                    items: [
                      for (final staticQuestion in remainingStaticQuestions)
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
                  ),
                  TextFormBox(
                    placeholder: "Answer for question ${index + 1}",
                    validator: (value) => validateSecurityAnswer(value, index),
                    onChanged: (value) {
                      context.read<UserFormBloc>().add(AnswerFieldChangedEvent(value, index));
                    },
                  ),
                ].withSpacing(() => Spacing.v8),
              ),
          ].withSpacing(() => Spacing.v16),
        ),
        Spacing.v8,
        const CaptionText(
          'Each security question can be chosen from the'
          ' defined list, or a custom question can be entered.',
        ),
      ],
    );
  }
}
