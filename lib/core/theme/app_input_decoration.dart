import 'package:flutter/material.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';

InputDecoration appInputDecoration({
  required String label,
  String? hint,
  String? helper,
  String? prefixText,
  Widget? suffixIcon,
  bool locked = false,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixText: prefixText,
    suffixIcon: locked
        ? const Icon(Icons.lock_outline_rounded, size: 18)
        : suffixIcon,
    counterText: '',
    filled: true,
    fillColor: locked ? const Color(0xFFF3F4F6) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(AppColors.border),
    disabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary, 1.5),
    errorBorder: border(const Color(0xFFDC2626)),
    focusedErrorBorder: border(const Color(0xFFDC2626), 1.5),
  );
}