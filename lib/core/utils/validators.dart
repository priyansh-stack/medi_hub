class Validators {
  Validators._();

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Full name cannot exceed 100 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim();
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid 10-15 digit phone number';
    }
    return null;
  }

  static String? validateAddressLine(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street / house address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address (at least 5 characters)';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    return null;
  }

  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length < 2) {
      return 'State name must be at least 2 characters';
    }
    return null;
  }

  static String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    if (value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal / PIN code is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 10) {
      return 'Please enter a valid postal / PIN code';
    }
    return null;
  }

  static String? validatePinCode(String? value) => validatePostalCode(value);

  static DateTime? parseFlexibleDate(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;

    // DD/MM/YYYY or DD-MM-YYYY
    final dmyRegex = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})$');
    final match = dmyRegex.firstMatch(clean);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    return DateTime.tryParse(clean);
  }

  static String? validateDateString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of birth is required';
    }
    final parsed = parseFlexibleDate(value);
    if (parsed == null) {
      return 'Please enter a valid date (DD/MM/YYYY)';
    }
    return validateDateOfBirth(parsed);
  }

  static String? validateDob(String? value) => validateDateString(value);

  static String? validateDateOfBirth(DateTime? dob) {
    if (dob == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    if (dob.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    final maxAge = now.subtract(const Duration(days: 365 * 125));
    if (dob.isBefore(maxAge)) {
      return 'Please enter a valid date of birth';
    }
    return null;
  }

  static String? validateFamilyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Family name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Family name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Family name cannot exceed 100 characters';
    }
    return null;
  }

  static String? validateFamilyDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length > 250) {
      return 'Description cannot exceed 250 characters';
    }
    return null;
  }
}
