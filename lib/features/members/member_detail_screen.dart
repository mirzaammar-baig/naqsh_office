import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/member_form_screen.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  // Confirmation dialog ke baad status badalta hai. Delete ka option hai hi nahi.
  Future<void> _confirmToggle(
      BuildContext context,
      WidgetRef ref,
      Member member,
      ) async {
    final activate = !member.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(activate ? 'Activate member?' : 'Deactivate member?'),
          content: Text(
            activate
                ? '${member.fullName} will be marked as Active.'
                : '${member.fullName} will be marked as Inactive. '
                'The record is kept and can be activated again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: activate
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              child: Text(activate ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ref.read(membersProvider.notifier).setActive(member.id, activate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Taaza member Notifier se dhoondo, taake edit ke baad detail update ho.
    final matches = ref.watch(membersProvider).where((m) => m.id == memberId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Detail')),
        body: const Center(child: Text('Member not found')),
      );
    }
    final member = matches.first;

    final accent = member.isActive ? AppColors.primary : AppColors.textMuted;
    final statusColor =
    member.isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280);
    final activate = !member.isActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Member Detail')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemberFormScreen(member: member),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Member',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _confirmToggle(context, ref, member),
                    style: FilledButton.styleFrom(
                      backgroundColor: activate
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      activate
                          ? Icons.check_circle_outline_rounded
                          : Icons.block_rounded,
                      size: 18,
                    ),
                    label: Text(
                      activate ? 'Activate' : 'Deactivate',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.memberNo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Pill(text: member.statusText, color: statusColor),
                          _Pill(
                            text: member.typeText,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14101828),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Relation', value: member.relationText),
                const Divider(),
                _InfoRow(label: 'CNIC', value: member.maskedCnic),
                const Divider(),
                _InfoRow(label: 'Phone', value: member.phone),
                const Divider(),
                _InfoRow(
                  label: 'Email',
                  value: member.email.isEmpty ? 'Not provided' : member.email,
                ),
                const Divider(),
                _InfoRow(label: 'Address', value: member.address),
                const Divider(),
                _InfoRow(label: 'City', value: member.city),
                const Divider(),
                _InfoRow(label: 'Member type', value: member.typeText),
                const Divider(),
                _InfoRow(label: 'Created', value: _formatDate(member.createdAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}