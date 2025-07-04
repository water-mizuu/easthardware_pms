import 'dart:async';

import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/security_questions/'
    'security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_form/user_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_question.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/auto_auto_suggest_box.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/success_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({required this.user, super.key});
  final User user;

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  List<SecurityQuestion>? _securityQuestions;
  UserFormBloc? userFormBloc;

  // Form field controllers
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController usernameController;

  List<SingleChildWidget> get providers {
    return [
      BlocProvider<UserFormBloc>.value(value: userFormBloc!),
    ];
  }

  List<SingleChildWidget> get listeners {
    return [
      // Status change listeners
      BlocListener<UserFormBloc, UserFormState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) async {
          switch (state.status) {
            case FormStatus.initial:
              if (isDebugMode) {
                printBoxed('User ID: ${state.userId}', 'EditUserPage - Initial');
              }
              break;
            case FormStatus.validating:
              if (isDebugMode) {
                printBoxed('Validating user form...', 'EditUserPage - Validating');
              }
              break;
            case FormStatus.submitting:
              if (isDebugMode) {
                final info = [
                  '- User ID: ${state.userId}',
                  'Name: ${state.firstName} ${state.lastName}',
                  'Username: ${state.username}',
                  'Access Level: ${state.accessLevel}',
                  'UID: ${state.uid}',
                ].join('\n -');
                printBoxed(info, 'EditUserPage - Submitting');
              }
              // Add the update user event to the UserListBloc
              context.read<UserListBloc>().add(
                    UpdateUserEvent(
                      state.copyWith(creationDate: widget.user.creationDate).mapStateToUser(),
                    ),
                  );

              final questions = state.questions.toList();
              final userId = state.userId!;
              // Add the security questions update event
              for (var i = 0; i < questions.length; i++) {
                final question = questions[i];
                context.read<SecurityQuestionListBloc>().add(UpdateSecurityQuestionEvent(
                      question.toSecurityQuestion(userId),
                    ));
              }
              // Update the security questions
              context.read<UserListBloc>().add(const LoadAllUsersEvent());
              // This makes the form status be submitted
              context.read<UserFormBloc>().add(FormResetEvent());

              // Show success message and navigate back
              await context.showSuccessDialog(
                title: 'User Updated',
                body: 'The user \'${state.username}\' has been successfully updated.',
              );
              if (!context.mounted) break;

              final user = context.read<AuthenticationBloc>().state.user!;
              context.read<UserLogListBloc>().add(AddUpdateEvent('User #${state.userId}', user));

              context.navigate(AppRoutes.admin.users);
              break;
            case FormStatus.error:
              if (isDebugMode) {
                printBoxed(
                    'Error submitting form: ${state.accessLevelErrorMessage}', 'EditUserPage');
              }
              showNotification(
                title: 'Error',
                message:
                    'Failed to update user: ${state.accessLevelErrorMessage ?? "Unknown error"}',
                severity: InfoBarSeverity.error,
              );
              break;
            default:
              break;
          }
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    usernameController = TextEditingController();

    // Add listeners to controllers
    _setupControllerListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize form bloc
    final currentQuestions = context.watch<SecurityQuestionListBloc>().state.securityQuestions;
    if (currentQuestions != _securityQuestions) {
      final questions = currentQuestions
          .where((q) => q.userId == widget.user.id) // Filter out archived questions
          .map((q) => FormQuestion.fromSecurityQuestion(q))
          .toList();

      unawaited(userFormBloc?.close());
      userFormBloc = UserFormBloc(UserFormState.fromUser(widget.user, questions));

      // Initialize controllers

      firstNameController.text = userFormBloc!.state.firstName;
      lastNameController.text = userFormBloc!.state.lastName;
      usernameController.text = userFormBloc!.state.username;
    }
  }

  void _setupControllerListeners() {
    firstNameController.addListener(() {
      userFormBloc?.add(FirstNameFieldChangedEvent(firstNameController.text));
    });

    lastNameController.addListener(() {
      userFormBloc?.add(LastNameFieldChangedEvent(lastNameController.text));
    });

    usernameController.addListener(() {
      userFormBloc?.add(UsernameFieldChangedEvent(usernameController.text));
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();

    unawaited(userFormBloc!.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocListener(
        listeners: listeners,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppPadding.panePadding.copyWith(bottom: 0.0),
              child: const PageHeader(),
            ),
            Expanded(
              child: AnimatedSingleChildScrollView(
                child: Padding(
                  padding: AppPadding.a16,
                  child: Container(
                    padding: AppPadding.panePadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Form(
                      key: userFormBloc!.formKey,
                      child: LayoutMode.builder((context, mode, keys) {
                        switch (mode) {
                          case LayoutMode.wide:
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: UserCredentialsSection(
                                    key: keys['userCredentials'],
                                    firstNameController: firstNameController,
                                    lastNameController: lastNameController,
                                    usernameController: usernameController,
                                  ),
                                ),
                                Spacing.h16,
                                Expanded(child: SecuritySection(key: keys['securitySection'])),
                              ],
                            );
                          case LayoutMode.constrained:
                          case LayoutMode.compact:
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                UserCredentialsSection(
                                  key: keys['userCredentials'],
                                  firstNameController: firstNameController,
                                  lastNameController: lastNameController,
                                  usernameController: usernameController,
                                ),
                                Spacing.v16,
                                SecuritySection(key: keys['securitySection']),
                              ],
                            );
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserFormBloc>().state;
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.users),
        ),
        const HeadingText('Edit User'),
        const Spacer(flex: 1),
        TextButton(
          'Archive User',
          onPressed: () {
            unawaited(showDialog<String>(
              context: context,
              builder: (dialogContext) => ContentDialog(
                title: const Text('Archive User?'),
                content: const Text(
                  'When archived, this user won\'t be able to log in. Do you want to proceed?',
                ),
                actions: [
                  Button(
                    child: const Text('Archive'),
                    onPressed: () {
                      for (final e in context.read<UserListBloc>().state.users) {
                        printBoxed(e.toMap());
                      }
                      final user = context
                          .read<UserListBloc>()
                          .state
                          .users
                          .firstWhere((u) => u.id == state.userId);
                      context.read<UserListBloc>().add(
                            UpdateUserEvent(
                              user.copyWith(
                                archiveStatus:
                                    user.archiveStatus == 0 ? 1 : 0, // Toggle archive status
                              ),
                            ),
                          );
                      context.read<UserLogListBloc>().add(
                            AddArchiveEvent(
                              'User #${state.userId}',
                              context.read<AuthenticationBloc>().state.user!,
                            ),
                          );
                      Navigator.pop(dialogContext, 'User archived');
                      context.navigate(AppRoutes.admin.users);
                    },
                  ),
                  FilledButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            ));
          },
        ),
        TextButtonFilled(
          'Update User',
          onPressed: () {
            // Trigger the validation and update process through the UpdateUserRequestEvent
            context.read<UserFormBloc>().add(UpdateUserRequestEvent());
          },
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserCredentialsSection extends StatelessWidget {
  const UserCredentialsSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubheadingText('User Information'),
          FirstNameLastNameFields(
            firstNameController: firstNameController,
            lastNameController: lastNameController,
          ),
          UsernameField(controller: usernameController),
          const OldPasswordField(),
          const PasswordField(),
          const ConfirmPasswordField(),
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }
}

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SubheadingText('Account Information'),
          AccessLevelField(),
          SecurityQuestionFields(),
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }
}

class FirstNameLastNameFields extends StatelessWidget with UserFormValidator {
  const FirstNameLastNameFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<UserFormBloc, UserFormState>(
            buildWhen: (p, c) => p.firstName != c.firstName,
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BodyText('First Name'),
                  TextFormBox(
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[a-zA-Z\s]*$'),
                        replacementString: context.select((UserFormBloc b) => b.state.firstName),
                      ),
                    ],
                    validator: validateFirstName,
                    placeholder: 'First Name',
                    controller: firstNameController,
                  ),
                ].withSpacing(() => Spacing.v8),
              );
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<UserFormBloc, UserFormState>(
            buildWhen: (p, c) => p.lastName != c.lastName,
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BodyText('Last Name'),
                  TextFormBox(
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[a-zA-Z\s]*$'),
                        replacementString: context.select((UserFormBloc b) => b.state.lastName),
                      ),
                    ],
                    validator: validateLastName,
                    placeholder: 'Last Name',
                    controller: lastNameController,
                  ),
                ].withSpacing(() => Spacing.v8),
              );
            },
          ),
        ),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UsernameField extends StatelessWidget with UserFormValidator {
  const UsernameField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

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
        BlocBuilder<UserFormBloc, UserFormState>(
          buildWhen: (p, c) => p.username != c.username,
          builder: (context, state) {
            // Filter out current username to allow keeping the same username
            final currentUsername = state.username;
            final otherUsernames =
                existingUsernames.where((username) => username != currentUsername).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BodyText('Username'),
                TextFormBox(
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(30),
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^[a-zA-Z0-9_]*$'),
                      replacementString: context.select((UserFormBloc b) => b.state.username),
                    ),
                  ],
                  placeholder: 'Enter username',
                  controller: controller,
                  validator: (value) => validateUsername(value, otherUsernames),
                ),
              ].withSpacing(() => Spacing.v8),
            );
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
    final state = context.watch<UserFormBloc>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('New Password'),
        ValueListenableBuilder(
          valueListenable: _isObscuredNotifier,
          builder: (context, isObscured, _) => BlocBuilder<UserFormBloc, UserFormState>(
            buildWhen: (p, c) => p.password != c.password,
            builder: (context, state) {
              return TextFormBox(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60),
                  FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))
                ],
                placeholder: 'Password',
                obscureText: isObscured,
                onChanged: (value) =>
                    context.read<UserFormBloc>().add(PasswordFieldChangedEvent(value)),
                suffix: IconButton(
                  icon: Icon(isObscured ? FluentIcons.hide : FluentIcons.red_eye),
                  onPressed: () {
                    _isObscuredNotifier.value = !isObscured;
                  },
                ),
              );
            },
          ),
        ),
        const CaptionText(
          'Leave password fields blank to keep the current password. If updating, password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.',
        ),
        if (state.passwordErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ErrorText(state.passwordErrorMessage!),
          ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class ConfirmPasswordField extends StatefulWidget {
  const ConfirmPasswordField({
    super.key,
  });

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> with UserFormValidator {
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
    final state = context.watch<UserFormBloc>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Confirm Password'),
        ValueListenableBuilder(
          valueListenable: _isObscuredNotifier,
          builder: (context, isObscured, _) => BlocBuilder<UserFormBloc, UserFormState>(
            buildWhen: (p, c) => p.password != c.password || p.confirmPassword != c.confirmPassword,
            builder: (context, state) {
              return TextFormBox(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60),
                  FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                ],
                validator: (value) {
                  final password = state.password;
                  // Only validate if both old password and new password are provided
                  if (state.oldPassword.isNotEmpty && password.isNotEmpty) {
                    return validateConfirmPassword(value, password);
                  } else if (value != null && value.isNotEmpty && password.isEmpty) {
                    return 'Please enter the new password';
                  } else if (value == null || value.isEmpty) {
                    if (password.isNotEmpty || state.oldPassword.isNotEmpty) {
                      return 'Please confirm the new password';
                    }
                  }
                  return null;
                },
                placeholder: 'Confirm Password',
                obscureText: isObscured,
                onChanged: (value) =>
                    context.read<UserFormBloc>().add(ConfirmPasswordFieldChangedEvent(value)),
                suffix: IconButton(
                  icon: Icon(isObscured ? FluentIcons.hide : FluentIcons.red_eye),
                  onPressed: () {
                    _isObscuredNotifier.value = !isObscured;
                  },
                ),
              );
            },
          ),
        ),
        if (state.confirmPasswordErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ErrorText(state.confirmPasswordErrorMessage!),
          ),
      ].withSpacing(() => Spacing.v8),
    );
  }
}

class OldPasswordField extends StatefulWidget {
  const OldPasswordField({super.key});

  @override
  State<OldPasswordField> createState() => _OldPasswordFieldState();
}

class _OldPasswordFieldState extends State<OldPasswordField> with UserFormValidator {
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
    final state = context.watch<UserFormBloc>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BodyText('Old Password'),
        ValueListenableBuilder(
          valueListenable: _isObscuredNotifier,
          builder: (context, isObscured, _) => BlocBuilder<UserFormBloc, UserFormState>(
            buildWhen: (p, c) => p.oldPassword != c.oldPassword,
            builder: (context, state) {
              return TextFormBox(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(60),
                  FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                ],
                validator: (value) => value != null && value.isNotEmpty && state.password.isNotEmpty
                    ? validatePassword(value)
                    : null,
                obscureText: isObscured,
                onChanged: (value) =>
                    context.read<UserFormBloc>().add(OldPasswordFieldChangedEvent(value)),
                suffix: IconButton(
                  icon: Icon(isObscured ? FluentIcons.hide : FluentIcons.red_eye),
                  onPressed: () {
                    _isObscuredNotifier.value = !isObscured;
                  },
                ),
              );
            },
          ),
        ),
        if (state.oldPasswordErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ErrorText(state.oldPasswordErrorMessage!),
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
      buildWhen: (p, c) =>
          p.accessLevel != c.accessLevel || p.accessLevelErrorMessage != c.accessLevelErrorMessage,
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Access Level', style: TextStyles.body),
            Spacing.v8,
            ComboBox(
              placeholder: const BodyText('Select Access Level'),
              value: state.accessLevel,
              isExpanded: true,
              items: AccessLevel.values.map((level) {
                return ComboBoxItem(
                  value: level.name,
                  child: Text(level.toString(), style: TextStyles.body),
                );
              }).toList(),
            ),
            if (state.accessLevelErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ErrorText(state.accessLevelErrorMessage!),
              ),
          ],
        );
      },
    );
  }
}

class SecurityQuestionFields extends StatefulWidget {
  const SecurityQuestionFields({super.key});

  @override
  State<SecurityQuestionFields> createState() => _SecurityQuestionFieldsState();
}

class _SecurityQuestionFieldsState extends State<SecurityQuestionFields> with UserFormValidator {
  late final List<TextEditingController> _questionControllers;
  late final List<TextEditingController> _answerControllers;
  // List of value notifiers to track obscuring state
  late final List<ValueNotifier<bool>> _obscureAnswerNotifiers;

  @override
  void initState() {
    super.initState();

    final userFormBloc = context.read<UserFormBloc>();

    if (isDebugMode) {
      printBoxed(userFormBloc.state.questions.map((q) => (q.question, q.answer)));
    }

    _questionControllers = List.generate(
      userFormBloc.state.questions.length,
      (i) => TextEditingController(text: userFormBloc.state.questions[i].question),
    );
    _answerControllers = List.generate(
      userFormBloc.state.questions.length,
      (i) => TextEditingController(text: userFormBloc.state.questions[i].answer),
    );

    // Initialize all answer fields to be obscured
    _obscureAnswerNotifiers = List.generate(
      userFormBloc.state.questions.length,
      (_) => ValueNotifier<bool>(true),
    );
  }

  @override
  void dispose() {
    for (final controller in _questionControllers.followedBy(_answerControllers)) {
      controller.dispose();
    }

    // Dispose the value notifiers
    for (final notifier in _obscureAnswerNotifiers) {
      notifier.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current questions from the form bloc for UI rendering
    final formQuestionsForUI = context.select((UserFormBloc b) => b.state.questions);
    final remainingStaticQuestions = SECURITY_QUESTIONS //
        .where((question) => !formQuestionsForUI.any((e) => e.question == question))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, _) in formQuestionsForUI.indexed)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BodyText('Security Question ${index + 1}'),
                  AutoAutoSuggestBox<String>(
                    placeholder: _questionControllers[index].text,
                    controller: _questionControllers[index],
                    items: remainingStaticQuestions
                        .map((q) => AutoSuggestBoxItem<String>(value: q, label: q))
                        .toList(),
                    onSelected: (value) {
                      context //
                          .read<UserFormBloc>()
                          .add(QuestionFieldChangedEvent(value.value ?? '', index));
                    },
                    onChanged: (value, reason) {
                      context.read<UserFormBloc>().add(
                            QuestionFieldChangedEvent(
                              value,
                              index,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  BodyText('Answer ${index + 1}'),
                  // Use ValueListenableBuilder to rebuild only this TextFormBox when obscured state changes
                  ValueListenableBuilder(
                    valueListenable: _obscureAnswerNotifiers[index],
                    builder: (context, isObscured, _) {
                      return TextFormBox(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(120),
                          FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                        ],
                        controller: _answerControllers[index],
                        placeholder: 'Answer',
                        validator: (value) => validateSecurityAnswer(value, index),
                        obscureText: isObscured,
                        onChanged: (value) {
                          context.read<UserFormBloc>().add(AnswerFieldChangedEvent(value, index));
                        },
                      );
                    },
                  ),
                ].withSpacing(() => Spacing.v8),
              ),
          ],
        ),
        Spacing.v8,
        const CaptionText(
          'Each security question can be chosen from the'
          ' defined list, or a custom question can be entered. Answers are case-sensitive.',
        ),
      ],
    );
  }
}

extension UserFormValidatorExtension on UserFormValidator {
  // Optional password validation for edit form
  String? validatePasswordOptional(String? value) {
    if (value == null || value.isEmpty) {
      // Password is optional when editing
      return null;
    }
    return validatePassword(value);
  }

  // Optional confirm password validation for edit form
  String? validateConfirmPasswordOptional(String? value, String password) {
    if ((value == null || value.isEmpty) && (password.isEmpty)) {
      // Both fields can be empty to keep current password
      return null;
    }
    return validateConfirmPassword(value, password);
  }
}
