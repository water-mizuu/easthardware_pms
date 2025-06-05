mixin UserFormValidator {
  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a first name';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters long';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a last name';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters long';
    }
    return null;
  }

  String? validateUsername(String? value, List<String> existingUsernames) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (existingUsernames.contains(value)) {
      return 'Username already exists';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    if (!value.contains(RegExp(r'[a-z]')) ||
        !value.contains(RegExp(r'[A-Z]')) ||
        !value.contains(RegExp(r'[0-9]')) ||
        !value.contains(RegExp(r'[@$!%*?&]'))) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateSecurityQuestion(String? value, List<String> questions, int index) {
    if (value == null || value.isEmpty) {
      if (index == 0) {
        return 'Question must not be empty';
      }
      return 'Three questions are required';
    }
    if (questions.contains(value)) {
      return 'This security question already exists';
    }
    return null;
  }

  String? validateSecurityAnswer(String? value, int index) {
    if (value == null || value.isEmpty) {
      if (index == 0) {
        return 'Answer must not be empty';
      }
      return 'Three questions are required';
    }
    if (value.length < 3) {
      return 'Answer must be at least 3 characters long';
    }
    return null;
  }
}
