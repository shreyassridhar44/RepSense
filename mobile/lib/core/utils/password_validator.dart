enum PasswordStrength {
  weak,
  fair,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  int get color {
    switch (this) {
      case PasswordStrength.weak:
        return 0xFFEF4444; // Red
      case PasswordStrength.fair:
        return 0xFFF59E0B; // Amber
      case PasswordStrength.strong:
        return 0xFF10B981; // Emerald
    }
  }
}

/// Pure utility class for password validation
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  /// Check password strength
  static PasswordStrength getStrength(String password) {
    if (password.length < minLength) return PasswordStrength.weak;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final varietyCount = [hasUppercase, hasLowercase, hasDigit, hasSpecial]
        .where((has) => has)
        .length;

    if (varietyCount >= 3 && password.length >= minLength) {
      return PasswordStrength.strong;
    }

    if (varietyCount >= 2 && password.length >= minLength) {
      return PasswordStrength.fair;
    }

    return PasswordStrength.weak;
  }

  /// Validate password meets minimum requirements
  static String? validate(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigit) {
      return 'Password must contain uppercase, lowercase, and a number';
    }

    return null;
  }

  /// Check if passwords match
  static String? validateConfirm(String password, String confirm) {
    if (confirm.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirm) {
      return 'Passwords don\'t match';
    }

    return null;
  }
}
