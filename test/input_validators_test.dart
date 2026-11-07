import 'package:flutter_test/flutter_test.dart';
import 'package:naqsh_office/core/utils/input_validators.dart';

void main() {
  group('Block code', () {
    test('valid new code passes', () {
      expect(
        InputValidators.blockCode('D', exists: (code) => false),
        isNull,
      );
    });

    test('duplicate code shows error', () {
      expect(
        InputValidators.blockCode('A', exists: (code) => code == 'A'),
        'Block A already exists.',
      );
    });

    test('empty and too long codes fail', () {
      expect(
        InputValidators.blockCode('', exists: (code) => false),
        'Block code is required',
      );
      expect(
        InputValidators.blockCode('ABCDEF', exists: (code) => false),
        'Use 1 to 5 capital letters or digits',
      );
    });
  });

  group('Plot number, size and price', () {
    test('plot number must be 1 to 9999', () {
      expect(InputValidators.plotNumber('7'), isNull);
      expect(InputValidators.plotNumber('0'), 'Enter a number from 1 to 9999');
      expect(
        InputValidators.plotNumber('10000'),
        'Enter a number from 1 to 9999',
      );
      expect(InputValidators.plotNumber('ab'), 'Digits only');
    });

    test('width allows one decimal and 1 to 999', () {
      expect(InputValidators.dimension('30', 'Width'), isNull);
      expect(InputValidators.dimension('22.5', 'Width'), isNull);
      expect(
        InputValidators.dimension('22.55', 'Width'),
        'Enter a number like 25 or 22.5',
      );
      expect(
        InputValidators.dimension('1000', 'Width'),
        'Width must be between 1 and 999',
      );
    });

    test('price must be digits, max 9 digits and not zero', () {
      expect(InputValidators.priceRupees('3000000'), isNull);
      expect(InputValidators.priceRupees('0'), 'Price cannot be 0');
      expect(
        InputValidators.priceRupees('1234567890'),
        'Price can have at most 9 digits',
      );
    });
  });

  group('Member fields', () {
    test('CNIC needs 13 digits, dashes are allowed', () {
      expect(InputValidators.cnic('00000-0001001-1'), isNull);
      expect(InputValidators.cnic('123'), 'CNIC must have 13 digits');
      expect(InputValidators.cnic(''), 'CNIC is required');
    });

    test('local phone: 11 digits starting with 03', () {
      expect(InputValidators.phone('03001234567', isOverseas: false), isNull);
      expect(
        InputValidators.phone('03123', isOverseas: false),
        'Enter 11 digits starting with 03',
      );
      expect(
        InputValidators.phone('04001234567', isOverseas: false),
        'Enter 11 digits starting with 03',
      );
    });

    test('overseas phone: + and 8 to 15 digits', () {
      expect(
        InputValidators.phone('+971501234567', isOverseas: true),
        isNull,
      );
      expect(
        InputValidators.phone('03001234567', isOverseas: true),
        'Use + followed by 8 to 15 digits',
      );
    });

    test('person name length and characters', () {
      expect(InputValidators.personName('Ali Khan', 'Full name'), isNull);
      expect(
        InputValidators.personName('Al', 'Full name'),
        'Full name must be 3 to 60 characters',
      );
      expect(InputValidators.personName('Ali@Khan', 'Full name'), isNotNull);
    });

    test('email is optional but must be valid when given', () {
      expect(InputValidators.email(''), isNull);
      expect(InputValidators.email('name@example.com'), isNull);
      expect(InputValidators.email('abc'), 'Enter a valid email address');
    });
  });

  group('CNIC formatting', () {
    test('formatCnic adds dashes', () {
      expect(formatCnic('0000000010011'), '00000-0001001-1');
    });

    test('formatter blocks letters and limits to 13 digits', () {
      final formatter = CnicInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'ab12345678901234'),
      );
      expect(result.text, '12345-6789012-3');
    });
  });
}