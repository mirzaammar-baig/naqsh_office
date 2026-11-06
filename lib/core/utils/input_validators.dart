import 'package:flutter/services.dart';

class InputValidators {
  InputValidators._();

  // ---------- Aam ----------

  // Khali na ho aur max length se zyada na ho.
  static String? requiredWithMax(String? value, String label, int max) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$label is required';
    }
    if (text.length > max) {
      return '$label must be at most $max characters';
    }
    return null;
  }

  // required: false ho to khali email theek hai (optional field).
  static String? email(String? value, {bool required = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return required ? 'Email is required' : null;
    }
    if (text.length > 100) {
      return 'Email must be at most 100 characters';
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ---------- Plots ----------

  static String? blockCode(
      String? value, {
        required bool Function(String code) exists,
      }) {
    final code = (value ?? '').trim();
    if (code.isEmpty) {
      return 'Block code is required';
    }
    if (!RegExp(r'^[A-Z0-9]{1,5}$').hasMatch(code)) {
      return 'Use 1 to 5 capital letters or digits';
    }
    if (exists(code)) {
      return 'Block $code already exists.';
    }
    return null;
  }

  static String? plotNumber(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Plot number is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return 'Digits only';
    }
    final number = int.tryParse(text);
    if (number == null || number < 1 || number > 9999) {
      return 'Enter a number from 1 to 9999';
    }
    return null;
  }

  // Width ya Length: 1 se 999, 1 decimal allowed (jaise 25 ya 22.5).
  static String? dimension(String? value, String label) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$label is required';
    }
    if (!RegExp(r'^\d+(\.\d)?$').hasMatch(text)) {
      return 'Enter a number like 25 or 22.5';
    }
    final number = double.parse(text);
    if (number < 1 || number > 999) {
      return '$label must be between 1 and 999';
    }
    return null;
  }

  // Price Rupees mein: digits only, max 9 digits, 0 nahi.
  static String? priceRupees(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Price is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return 'Digits only';
    }
    if (text.length > 9) {
      return 'Price can have at most 9 digits';
    }
    if (int.parse(text) == 0) {
      return 'Price cannot be 0';
    }
    return null;
  }

  // ---------- Members ----------

  // Naam: letters aur spaces, 3 se 60.
  static String? personName(String? value, String label) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '$label is required';
    }
    if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(text)) {
      return '$label can have letters, digits and spaces only';
    }
    if (text.length < 3 || text.length > 60) {
      return '$label must be 3 to 60 characters';
    }
    return null;
  }

  // CNIC: dashes ke baghair 13 digits.
  static String? cnic(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'CNIC is required';
    }
    if (digits.length != 13) {
      return 'CNIC must have 13 digits';
    }
    return null;
  }

  // Local: 11 digits, 03 se shuru. Overseas: + ke saath 8 se 15 digits.
  static String? phone(String? value, {required bool isOverseas}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Phone is required';
    }
    if (isOverseas) {
      if (!RegExp(r'^\+\d{8,15}$').hasMatch(text)) {
        return 'Use + followed by 8 to 15 digits';
      }
    } else {
      if (!RegExp(r'^03\d{9}$').hasMatch(text)) {
        return 'Enter 11 digits starting with 03';
      }
    }
    return null;
  }

  // Phone field mein kya type ho sakta hai.
  static List<TextInputFormatter> phoneFormatters({required bool isOverseas}) {
    if (isOverseas) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(16),
      ];
    }
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
    ];
  }
}

// ---------- Typing ke waqt formatting ----------

// Block code type karte hi capital ho jaye.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// CNIC: sirf digits, max 13, aur khud 00000-0000000-0 ban jaye.
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final nonDigits = RegExp(r'\D');
    final oldDigits = oldValue.text.replaceAll(nonDigits, '');
    var digits = newValue.text.replaceAll(nonDigits, '');

    // Dash delete karne par ek digit bhi hata do, warna cursor atak jata hai.
    final deleted = newValue.text.length < oldValue.text.length;
    if (deleted && digits.length == oldDigits.length && digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }

    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    final formatted = formatCnic(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// 0000000010011 ko 00000-0000100-11 jaisa format karta hai.
String formatCnic(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 5 || i == 12) {
      buffer.write('-');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}