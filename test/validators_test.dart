import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/utils/validators.dart';

void main() {
  group('Validators Test Suite', () {
    const testEmail = 'test.user@medihub.health';

    test('validates valid test email correctly', () {
      expect(Validators.validateEmail(testEmail), isNull);
      expect(Validators.validateEmail('  TEST.USER@MEDIHUB.HEALTH  '), isNull);
      expect(Validators.normalizeEmail('  TEST.USER@MEDIHUB.HEALTH  '), equals('test.user@medihub.health'));
    });

    test('catches invalid email formats', () {
      expect(Validators.validateEmail(''), equals('Email address is required'));
      expect(Validators.validateEmail(null), equals('Email address is required'));
      expect(Validators.validateEmail('notanemail'), equals('Please enter a valid email address'));
      expect(Validators.validateEmail('@medihub.health'), equals('Please enter a valid email address'));
      expect(Validators.validateEmail('test@'), equals('Please enter a valid email address'));
    });

    test('validates full name boundaries (2 to 100 characters)', () {
      expect(Validators.validateFullName(''), equals('Full name is required'));
      expect(Validators.validateFullName('A'), equals('Full name must be at least 2 characters'));
      expect(Validators.validateFullName('Priyanshu Kumar'), isNull);
      expect(Validators.validateFullName('A' * 101), equals('Full name cannot exceed 100 characters'));
    });

    test('validates password strength (min 8 chars, letter + digit)', () {
      expect(Validators.validatePassword(''), equals('Password is required'));
      expect(Validators.validatePassword('short7'), equals('Password must be at least 8 characters long'));
      expect(Validators.validatePassword('alllettersonly'), equals('Password must contain at least one letter and one number'));
      expect(Validators.validatePassword('123456789'), equals('Password must contain at least one letter and one number'));
      expect(Validators.validatePassword('MediHubPass2026!'), isNull);
    });

    test('validates confirm password matching', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(Validators.validateConfirmPassword('pass123', 'different'), equals('Passwords do not match'));
      expect(Validators.validateConfirmPassword('', 'pass123'), equals('Please confirm your password'));
    });

    test('validates phone number requirement and length', () {
      expect(Validators.validatePhone(''), equals('Phone number is required'));
      expect(Validators.validatePhone(null), equals('Phone number is required'));
      expect(Validators.validatePhone('+91 98765 43210'), isNull);
      expect(Validators.validatePhone('12345'), equals('Please enter a valid 10-15 digit phone number'));
    });

    test('validates date of birth not in future and reasonable age', () {
      expect(Validators.validateDateOfBirth(null), equals('Date of birth is required'));
      expect(
        Validators.validateDateOfBirth(DateTime.now().add(const Duration(days: 1))),
        equals('Date of birth cannot be in the future'),
      );
      expect(
        Validators.validateDateOfBirth(DateTime(1800, 1, 1)),
        equals('Please enter a valid date of birth'),
      );
      expect(
        Validators.validateDateOfBirth(DateTime(1996, 5, 20)),
        isNull,
      );
    });

    test('validates family name (2 to 100 chars)', () {
      expect(Validators.validateFamilyName(''), equals('Family name is required'));
      expect(Validators.validateFamilyName('A'), equals('Family name must be at least 2 characters'));
      expect(Validators.validateFamilyName('The Kumar Household'), isNull);
    });
  });
}
