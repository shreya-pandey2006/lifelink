/// LifeLink input validation suite.
/// Provides standardized validation logic and user-friendly error messages
/// for email, user name, password, age, weight, and clinical parameters.
class Validators {
  Validators._();

  // ---------------------------------------------------------------------------
  // User Name Validation
  // ---------------------------------------------------------------------------
  /// Validates a user's full name or username.
  /// - Non-empty
  /// - Minimum [minLength] (default 2) characters
  /// - Maximum [maxLength] (default 60) characters
  /// - Allowed characters: alphabetic letters (including accented/international letters),
  ///   spaces, hyphens, periods, and apostrophes.
  /// - Must contain at least 2 alphabetic letters (cannot be purely digits or symbols).
  static String? validateName(
    String? value, {
    String fieldName = 'Full Name',
    int minLength = 2,
    int maxLength = 60,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }

    final trimmed = value.trim();

    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (trimmed.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    // Must contain only letters, spaces, hyphens, periods, and apostrophes
    final allowedPattern = RegExp(r"^[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF\s\-'.]+$");
    if (!allowedPattern.hasMatch(trimmed)) {
      return '$fieldName can only contain letters, spaces, hyphens and apostrophes';
    }

    // Must contain at least two letters (not just "." or "-'")
    final letterCount = RegExp(r'[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF]').allMatches(trimmed).length;
    if (letterCount < minLength) {
      return '$fieldName must contain at least $minLength letters';
    }

    // Disallow consecutive special characters like ".." or "--" or multiple spaces
    if (RegExp(r"[\-'.]{2,}").hasMatch(trimmed)) {
      return '$fieldName cannot contain consecutive punctuation';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Email Validation
  // ---------------------------------------------------------------------------
  /// Validates an email address.
  /// - Non-empty
  /// - Maximum length 100 characters
  /// - Compliant with standard email address patterns (user@domain.tld)
  /// - Rejects keyboard smash consonant strings (e.g. fhgj)
  /// - Detects and flags common domain typos (e.g. gail.com -> gmail.com)
  /// - Blocks disposable/temporary email services
  /// - TLD must be at least 2 characters
  /// - No whitespace or invalid punctuation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final trimmed = value.trim();

    if (trimmed.length > 100) {
      return 'Email address cannot exceed 100 characters';
    }

    if (trimmed.contains(' ')) {
      return 'Email address cannot contain spaces';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed) || trimmed.contains('..')) {
      return 'Please enter a valid email address (e.g. name@example.com)';
    }

    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'Please enter a valid email address';
    }

    final username = parts[0];
    final domain = parts[1].toLowerCase();

    if (username.length < 2) {
      return 'Email username must be at least 2 characters';
    }

    // Reject pure consonant keyboard smashes with 3+ characters (e.g. "fhgj", "zxcv")
    if (username.length >= 3 && !RegExp(r'[aeiouyAEIOUY0-9]').hasMatch(username)) {
      return 'Please enter a valid, realistic email address';
    }

    // Common domain typo detection
    const commonTypos = {
      'gail.com': 'gmail.com',
      'gamil.com': 'gmail.com',
      'gmial.com': 'gmail.com',
      'gmai.com': 'gmail.com',
      'gmal.com': 'gmail.com',
      'gmaill.com': 'gmail.com',
      'gmaik.com': 'gmail.com',
      'gmaul.com': 'gmail.com',
      'gmeil.com': 'gmail.com',
      'yaho.com': 'yahoo.com',
      'yahooo.com': 'yahoo.com',
      'yhaoo.com': 'yahoo.com',
      'hotmial.com': 'hotmail.com',
      'hotmaill.com': 'hotmail.com',
      'hotmil.com': 'hotmail.com',
      'outlok.com': 'outlook.com',
      'outloo.com': 'outlook.com',
      'outlock.com': 'outlook.com',
      'icoud.com': 'icloud.com',
      'iclod.com': 'icloud.com',
    };

    if (commonTypos.containsKey(domain)) {
      return 'Invalid email domain: Did you mean @${commonTypos[domain]}?';
    }

    // Block temporary or disposable email addresses
    const disposableDomains = {
      'tempmail.com',
      '10minutemail.com',
      'mailinator.com',
      'guerrillamail.com',
      'throwawaymail.com',
      'trashmail.com',
      'fakeinbox.com',
      'yopmail.com',
      'sharklasers.com',
      'getnada.com',
      'dispostable.com',
      'temp-mail.org',
    };

    if (disposableDomains.contains(domain)) {
      return 'Temporary or disposable email addresses are not allowed';
    }

    final domainParts = domain.split('.');
    if (domainParts.length < 2 || domainParts.any((p) => p.isEmpty)) {
      return 'Please enter a valid email domain (e.g. gmail.com)';
    }

    final tld = domainParts.last;
    if (tld.length < 2 || !RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
      return 'Please enter a valid top-level domain (e.g. .com)';
    }

    if (domainParts.first.length < 2) {
      return 'Email domain name must be at least 2 characters';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Password Validation
  // ---------------------------------------------------------------------------
  /// Validates a password.
  /// - Non-empty
  /// - Minimum length [minLength] (default 6)
  /// - Maximum length [maxLength] (default 128)
  /// - When [requireMixed] is true (default for registration):
  ///   Must contain both at least one letter and at least one number.
  static String? validatePassword(
    String? value, {
    int minLength = 6,
    int maxLength = 128,
    bool requireMixed = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return 'Password cannot exceed $maxLength characters';
    }

    if (requireMixed) {
      final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      final hasDigit = RegExp(r'[0-9]').hasMatch(value);

      if (!hasLetter && !hasDigit) {
        return 'Password must contain at least one letter and one number';
      }
      if (!hasLetter) {
        return 'Password must contain at least one letter';
      }
      if (!hasDigit) {
        return 'Password must contain at least one number';
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Confirm Password Validation
  // ---------------------------------------------------------------------------
  /// Validates that confirmation password matches the original password.
  static String? validateConfirmPassword(
    String? confirmValue,
    String? originalPassword,
  ) {
    if (confirmValue == null || confirmValue.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirmValue != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Age Validation
  // ---------------------------------------------------------------------------
  /// Validates age as a whole positive integer within [min] and [max].
  /// - [min]: default 18 for donors, can be 0 or 1 for patients
  /// - [max]: default 100 (or 120 for patient requests)
  /// - [isDonor]: whether this is a donor eligibility validation
  /// - [required]: whether leaving this field blank is an error
  static String? validateAge(
    String? value, {
    int min = 18,
    int max = 100,
    String fieldName = 'Age',
    bool isDonor = false,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (!required) return null;
      return 'Please enter $fieldName';
    }

    final trimmed = value.trim();

    // Reject decimals for age (e.g. 25.5)
    if (trimmed.contains('.') || trimmed.contains(',')) {
      return '$fieldName must be a whole number, not a decimal';
    }

    final age = int.tryParse(trimmed);
    if (age == null) {
      return 'Please enter a valid age (whole number)';
    }

    if (age < min) {
      if (isDonor && min == 18) {
        return 'Donors must be at least 18 years old to donate blood';
      }
      return '$fieldName must be at least $min';
    }

    if (age > max) {
      return '$fieldName cannot exceed $max';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Weight Validation
  // ---------------------------------------------------------------------------
  /// Validates weight in kg (supports decimals e.g. 68.5).
  /// - [min]: minimum weight in kg (default 30.0, or 45.0 recommended for blood donors)
  /// - [max]: maximum weight in kg (default 300.0)
  /// - [isDonor]: whether this is a donor eligibility validation
  /// - [required]: whether leaving this field blank is an error
  static String? validateWeight(
    String? value, {
    double min = 30.0,
    double max = 300.0,
    String fieldName = 'Weight',
    bool isDonor = false,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (!required) return null;
      return 'Please enter $fieldName';
    }

    final trimmed = value.trim().replaceAll(',', '.');
    final weight = double.tryParse(trimmed);

    if (weight == null) {
      return 'Please enter a valid weight in kg (e.g. 68.5)';
    }

    if (weight <= 0) {
      return '$fieldName must be a positive number';
    }

    if (weight < min) {
      if (isDonor && min <= 45.0) {
        return 'Donors must weigh at least ${min.toInt()} kg (45+ kg recommended)';
      }
      return '$fieldName must be at least ${min.toStringAsFixed(min.truncateToDouble() == min ? 0 : 1)} kg';
    }

    if (weight > max) {
      return '$fieldName cannot exceed ${max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1)} kg';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Hemoglobin Validation
  // ---------------------------------------------------------------------------
  /// Validates hemoglobin in g/dL (e.g. 13.5).
  static String? validateHemoglobin(
    String? value, {
    double min = 3.0,
    double max = 25.0,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (!required) return null;
      return 'Please enter hemoglobin level';
    }

    final trimmed = value.trim().replaceAll(',', '.');
    final hb = double.tryParse(trimmed);

    if (hb == null) {
      return 'Please enter a valid hemoglobin value (e.g. 13.5)';
    }

    if (hb < min || hb > max) {
      return 'Hemoglobin must be between ${min.toStringAsFixed(1)} and ${max.toStringAsFixed(1)} g/dL';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone Number Validation
  // ---------------------------------------------------------------------------
  /// Validates 10-15 digit phone number.
  /// If [countryCode] is '+91' or the number is 10 digits, verifies it begins with 6-9.
  static String? validatePhone(String? value, {String? countryCode}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final clean = value.replaceAll(RegExp(r'[\s\-()+]'), '');

    if (!RegExp(r'^[0-9]+$').hasMatch(clean)) {
      return 'Phone number can only contain digits';
    }

    if (clean.length < 10) {
      return 'Enter a valid 10-digit phone number';
    }

    if (clean.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }

    if ((countryCode == '+91' || clean.length == 10) && clean.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(clean)) {
        return 'Enter a valid Indian mobile number starting with 6, 7, 8, or 9';
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Timeframe / Hours Validation
  // ---------------------------------------------------------------------------
  /// Validates hours required (e.g. 1 to 168 hours).
  static String? validateRequiredHours(
    String? value, {
    int min = 1,
    int max = 168,
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (!required) return null;
      return 'Please enter timeframe in hours';
    }

    final hrs = int.tryParse(value.trim());
    if (hrs == null) {
      return 'Hours must be a whole number';
    }

    if (hrs < min || hrs > max) {
      return 'Timeframe must be between $min and $max hours';
    }

    return null;
  }
}
