import 'package:flutter/material.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';

// Locked (badal na sakne wali) field: grey, lock icon ke saath.
class LockedField extends StatelessWidget {
  const LockedField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      style: const TextStyle(fontSize: 16),
      decoration: appInputDecoration(label: label, locked: true),
    );
  }
}

// Chhote options mein se ek chunna (jaise Yes ya No).
class SegmentField<T> extends StatelessWidget {
  const SegmentField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final entry in options.entries)
                ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
              selectedForegroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}