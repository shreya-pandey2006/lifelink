import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_app/core/validators.dart';

void main() {
  group('Validators - Name Validation', () {
    test('returns error when null or empty', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('   '), isNotNull);
    });

    test('returns error when name is too short', () {
      expect(Validators.validateName('A'), contains('at least 2 characters'));
    });

    test('returns error when name exceeds max length', () {
      final longName = 'A' * 61;
      expect(Validators.validateName(longName), contains('cannot exceed 60 characters'));
    });

    test('returns error when name contains invalid characters or numbers', () {
      expect(Validators.validateName('John123'), contains('can only contain letters'));
      expect(Validators.validateName('Sarah@Doe'), contains('can only contain letters'));
      expect(Validators.validateName('12345'), contains('can only contain letters'));
    });

    test('returns error when name has only punctuation and no letters', () {
      expect(Validators.validateName(".."), isNotNull);
      expect(Validators.validateName("--"), isNotNull);
    });

    test('accepts valid single and multi-word names with spaces, hyphens, and apostrophes', () {
      expect(Validators.validateName('John Doe'), isNull);
      expect(Validators.validateName('Mary-Jane Watson'), isNull);
      expect(Validators.validateName("O'Connor"), isNull);
      expect(Validators.validateName('Dr. Robert Smith'), isNull);
      expect(Validators.validateName('Renée Zellweger'), isNull);
    });
  });

  group('Validators - Email Validation', () {
    test('returns error when null or empty', () {
      expect(Validators.validateEmail(null), contains('enter your email'));
      expect(Validators.validateEmail(''), contains('enter your email'));
      expect(Validators.validateEmail('   '), contains('enter your email'));
    });

    test('returns error when email contains spaces', () {
      expect(Validators.validateEmail('user @example.com'), contains('cannot contain spaces'));
    });

    test('returns error when email is malformed', () {
      expect(Validators.validateEmail('notanemail'), contains('valid email address'));
      expect(Validators.validateEmail('user@'), contains('valid email address'));
      expect(Validators.validateEmail('@domain.com'), contains('valid email address'));
      expect(Validators.validateEmail('user@domain'), contains('valid email address'));
      expect(Validators.validateEmail('user@domain.'), contains('valid email address'));
      expect(Validators.validateEmail('user..name@domain.com'), contains('valid email address'));
    });

    test('returns error when email has domain typos (e.g. gail.com)', () {
      expect(Validators.validateEmail('shreya@gail.com'), contains('Did you mean @gmail.com?'));
      expect(Validators.validateEmail('user@yaho.com'), contains('Did you mean @yahoo.com?'));
      expect(Validators.validateEmail('user@hotmial.com'), contains('Did you mean @hotmail.com?'));
    });

    test('returns error when email username is pure consonant keyboard smash', () {
      expect(Validators.validateEmail('fhgj@gmail.com'), contains('valid, realistic email address'));
      expect(Validators.validateEmail('fhgj@gail.com'), isNotNull);
    });

    test('returns error for disposable email domains', () {
      expect(Validators.validateEmail('user@tempmail.com'), contains('disposable email'));
      expect(Validators.validateEmail('test@mailinator.com'), contains('disposable email'));
    });

    test('accepts valid email addresses', () {
      expect(Validators.validateEmail('elena.rostova@lifelink.org'), isNull);
      expect(Validators.validateEmail('user.name+tag@domain.co.uk'), isNull);
      expect(Validators.validateEmail('donor123@hospital.in'), isNull);
      expect(Validators.validateEmail('shreya.pandey@gmail.com'), isNull);
    });
  });

  group('Validators - Password Validation', () {
    test('returns error when null or empty', () {
      expect(Validators.validatePassword(null), contains('enter your password'));
      expect(Validators.validatePassword(''), contains('enter your password'));
    });

    test('returns error when password is too short', () {
      expect(Validators.validatePassword('abc'), contains('at least 6 characters'));
      expect(Validators.validatePassword('a1', minLength: 8), contains('at least 8 characters'));
    });

    test('returns error when password lacks letters or numbers with requireMixed', () {
      expect(Validators.validatePassword('123456', requireMixed: true), contains('at least one letter'));
      expect(Validators.validatePassword('abcdef', requireMixed: true), contains('at least one number'));
    });

    test('accepts valid passwords', () {
      expect(Validators.validatePassword('pass12', requireMixed: true), isNull);
      expect(Validators.validatePassword('SecurePass123!', requireMixed: true), isNull);
      expect(Validators.validatePassword('simple', requireMixed: false), isNull);
    });

    test('validates confirm password', () {
      expect(Validators.validateConfirmPassword(null, 'pass123'), contains('confirm your password'));
      expect(Validators.validateConfirmPassword('', 'pass123'), contains('confirm your password'));
      expect(Validators.validateConfirmPassword('pass1234', 'pass123'), contains('do not match'));
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
    });
  });

  group('Validators - Age Validation', () {
    test('handles required and non-required checks', () {
      expect(Validators.validateAge(null, required: false), isNull);
      expect(Validators.validateAge('', required: false), isNull);
      expect(Validators.validateAge(null, required: true), contains('Please enter Age'));
      expect(Validators.validateAge('', required: true), contains('Please enter Age'));
    });

    test('rejects decimals and non-numeric strings', () {
      expect(Validators.validateAge('25.5'), contains('whole number'));
      expect(Validators.validateAge('abc'), contains('valid age'));
    });

    test('enforces donor age range (18-100)', () {
      expect(Validators.validateAge('17', isDonor: true), contains('at least 18 years old'));
      expect(Validators.validateAge('101', isDonor: true), contains('cannot exceed 100'));
      expect(Validators.validateAge('18', isDonor: true), isNull);
      expect(Validators.validateAge('35', isDonor: true), isNull);
      expect(Validators.validateAge('65', isDonor: true), isNull);
      expect(Validators.validateAge('100', isDonor: true), isNull);
    });

    test('enforces patient age range (0-120)', () {
      expect(Validators.validateAge('-1', min: 0, max: 120, fieldName: 'Patient age'), contains('at least 0'));
      expect(Validators.validateAge('121', min: 0, max: 120, fieldName: 'Patient age'), contains('cannot exceed 120'));
      expect(Validators.validateAge('0', min: 0, max: 120, fieldName: 'Patient age'), isNull);
      expect(Validators.validateAge('45', min: 0, max: 120, fieldName: 'Patient age'), isNull);
    });
  });

  group('Validators - Weight Validation', () {
    test('handles required and non-required checks', () {
      expect(Validators.validateWeight(null, required: false), isNull);
      expect(Validators.validateWeight('', required: false), isNull);
      expect(Validators.validateWeight(null, required: true), contains('Please enter Weight'));
    });

    test('rejects non-numeric strings and negative numbers', () {
      expect(Validators.validateWeight('abc'), contains('valid weight in kg'));
      expect(Validators.validateWeight('0'), contains('positive number'));
      expect(Validators.validateWeight('-5'), contains('positive number'));
    });

    test('enforces donor weight range (30-300 kg, min 45+ recommended for donation)', () {
      expect(Validators.validateWeight('29', min: 30, max: 300, isDonor: true), contains('at least 30 kg'));
      expect(Validators.validateWeight('301', min: 30, max: 300, isDonor: true), contains('cannot exceed 300 kg'));
      expect(Validators.validateWeight('50', min: 30, max: 300, isDonor: true), isNull);
      expect(Validators.validateWeight('68.5', min: 30, max: 300, isDonor: true), isNull);
      expect(Validators.validateWeight('72,5', min: 30, max: 300, isDonor: true), isNull);
    });

    test('enforces patient weight range (1-300 kg)', () {
      expect(Validators.validateWeight('0.5', min: 1, max: 300, fieldName: 'Patient weight'), contains('at least 1 kg'));
      expect(Validators.validateWeight('75.2', min: 1, max: 300, fieldName: 'Patient weight'), isNull);
    });
  });

  group('Validators - Hemoglobin and Phone Validation', () {
    test('validates hemoglobin', () {
      expect(Validators.validateHemoglobin(null, required: true), contains('enter hemoglobin'));
      expect(Validators.validateHemoglobin('2.5'), contains('between 3.0 and 25.0 g/dL'));
      expect(Validators.validateHemoglobin('26'), contains('between 3.0 and 25.0 g/dL'));
      expect(Validators.validateHemoglobin('14.2'), isNull);
    });

    test('validates phone', () {
      expect(Validators.validatePhone(null), contains('enter your phone'));
      expect(Validators.validatePhone('12345'), contains('valid 10-digit'));
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('+91 98765 43210'), isNull);
    });
  });
}
