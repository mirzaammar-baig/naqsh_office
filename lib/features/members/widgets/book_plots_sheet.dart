import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';
import 'package:naqsh_office/features/members/widgets/earnest_section.dart';

// Plot(s) ko member ko do: earnest ke saath (Booked) ya bina (Hold).
// member diya ho to member chunna nahi parta (Member Detail se).
// Kamyabi par ek message wapas deti hai.
class BookPlotsSheet extends ConsumerStatefulWidget {
  const BookPlotsSheet({
    super.key,
    required this.title,
    required this.plotIds,
    this.member,
    this.members = const [],
  });

  final String title;
  final List<String> plotIds;

  // Pehle se tay member (Member Detail se).
  final Member? member;

  // member null ho to is list se chuna jata hai.
  final List<Member> members;

  @override
  ConsumerState<BookPlotsSheet> createState() => _BookPlotsSheetState();
}

class _BookPlotsSheetState extends ConsumerState<BookPlotsSheet> {
  final GlobalKey<EarnestSectionState> earnestKey =
  GlobalKey<EarnestSectionState>();

  Member? selected;
  int days = 3;
  bool isSaving = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    selected = widget.member;
  }

  Future<void> save() async {
    if (isSaving) {
      return;
    }
    final member = selected;
    if (member == null) {
      setState(() {
        errorText = 'Choose a member first.';
      });
      return;
    }

    final bookings = earnestKey.currentState?.collect();
    if (bookings == null) {
      setState(() {
        errorText = 'Please check the earnest amounts.';
      });
      return;
    }

    final notifier = ref.read(membersProvider.notifier);
    final navigator = Navigator.of(context);

    setState(() {
      isSaving = true;
      errorText = null;
    });

    try {
      final receipts = await notifier
          .assignPlots(member.id, bookings, holdDays: days)
          .timeout(const Duration(seconds: 15));
      final booked = receipts.length;
      final held = bookings.length - booked;
      final parts = [
        if (booked > 0) '$booked booked',
        if (held > 0) '$held on hold',
      ];
      navigator.pop('${parts.join(', ')} for ${member.fullName}');
    } on TimeoutException {
      showError('Could not reach the server. Check your internet.');
    } on StateError catch (error) {
      showError(error.message);
    } catch (error) {
      showError('Could not save: $error');
    }
  }

  void showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      isSaving = false;
      errorText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.member == null) ...[
              DropdownButtonFormField<Member>(
                initialValue: selected,
                isExpanded: true,
                decoration: appInputDecoration(label: 'Member'),
                items: [
                  for (final member in widget.members)
                    DropdownMenuItem(
                      value: member,
                      child: Text(
                        '${member.memberNo} - ${member.fullName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    selected = value;
                    errorText = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            EarnestSection(
              key: earnestKey,
              plotIds: widget.plotIds,
              holdDays: days,
            ),
            const SizedBox(height: 4),
            const Text(
              'Hold for (agar earnest nahi)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in const [1, 3, 7, 15])
                  ChoiceChip(
                    label: Text('$option day${option == 1 ? '' : 's'}'),
                    selected: days == option,
                    onSelected: (_) {
                      setState(() {
                        days = option;
                      });
                    },
                  ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: isSaving ? null : save,
                child: Text(isSaving ? 'Saving...' : 'Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}