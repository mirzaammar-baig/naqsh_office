import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/member_form_screen.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';
import 'package:naqsh_office/features/members/widgets/book_plots_sheet.dart';
import 'package:naqsh_office/features/members/widgets/plot_picker_field.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_detail_screen.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/widgets/block_badge.dart';
import 'package:naqsh_office/features/plots/widgets/status_chip.dart';

const Color _red = Color(0xFFDC2626);
const Color _green = Color(0xFF16A34A);

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  int _plotCount(WidgetRef ref, String id) {
    return ref.read(allPlotsProvider).where((p) => p.memberId == id).length;
  }

  void _showError(ScaffoldMessengerState messenger, Object error) {
    if (error is TimeoutException) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach the server. Check your internet and try again.',
          ),
        ),
      );
    } else if (error is StateError) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('Something went wrong: $error')));
    }
  }

  // Deactivate / Activate. Deactivate par member ke sab plots wapas Available.
  Future<void> _confirmToggle(
      BuildContext context,
      WidgetRef ref,
      Member member,
      ) async {
    final activate = !member.isActive;
    final notifier = ref.read(membersProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final plotCount = _plotCount(ref, member.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final plotNote = plotCount == 0
            ? ''
            : ' $plotCount plot${plotCount == 1 ? '' : 's'} will become Available again.';
        return AlertDialog(
          title: Text(activate ? 'Activate member?' : 'Deactivate member?'),
          content: Text(
            activate
                ? '${member.fullName} will be marked as Active.'
                : '${member.fullName} will be marked as Inactive.$plotNote '
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
                backgroundColor: activate ? _green : _red,
              ),
              child: Text(activate ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (activate) {
        await notifier
            .setActive(member.id, true)
            .timeout(const Duration(seconds: 10));
        messenger.showSnackBar(
          SnackBar(content: Text('${member.fullName} activated')),
        );
      } else {
        await notifier
            .deactivateMember(member.id)
            .timeout(const Duration(seconds: 10));
        messenger.showSnackBar(
          SnackBar(content: Text('${member.fullName} deactivated')),
        );
      }
    } catch (error) {
      _showError(messenger, error);
    }
  }

  // Delete: member mit jata hai, uske sab plots wapas Available.
  Future<void> _confirmDelete(
      BuildContext context,
      WidgetRef ref,
      Member member,
      ) async {
    final notifier = ref.read(membersProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final plotCount = _plotCount(ref, member.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final plotNote = plotCount == 0
            ? ''
            : ' $plotCount plot${plotCount == 1 ? '' : 's'} will become Available again.';
        return AlertDialog(
          title: Text('Delete ${member.memberNo}?'),
          content: Text(
            '${member.fullName} will be deleted permanently.$plotNote '
                'This cannot be undone. To keep the record, use Deactivate instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: _red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    navigator.pop();
    try {
      await notifier
          .deleteMember(member.id)
          .timeout(const Duration(seconds: 10));
      messenger.showSnackBar(
        SnackBar(content: Text('${member.memberNo} deleted')),
      );
    } catch (error) {
      _showError(messenger, error);
    }
  }

  // Chune hue plots member ko do: earnest wale Booked, baaqi Hold.
  Future<void> _assignPlots(
      BuildContext context,
      WidgetRef ref,
      Member member,
      List<String> plotIds,
      ) async {
    if (plotIds.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return BookPlotsSheet(
          title: 'Add plots for ${member.fullName}',
          plotIds: plotIds,
          member: member,
        );
      },
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
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

    // Is member ke plots.
    final memberPlots = [
      for (final plot in ref.watch(allPlotsProvider))
        if (plot.memberId == member.id) plot,
    ]..sort((a, b) => a.plotNumber.compareTo(b.plotNumber));
    final totalPaisa = memberPlots.fold<int>(
      0,
          (sum, plot) => sum + plot.pricePaisa,
    );

    final accent = member.isActive ? AppColors.primary : AppColors.textMuted;
    final statusColor = member.isActive ? _green : const Color(0xFF6B7280);
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
                      backgroundColor: activate ? _green : _red,
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

          // Plots
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plots (${memberPlots.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (memberPlots.isNotEmpty)
                Text(
                  'Rs ${formatWithCommas(totalPaisa ~/ 100)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (memberPlots.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'No plots yet.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            )
          else
            for (final plot in memberPlots)
              _MemberPlotTile(
                plot: plot,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlotDetailScreen(plotId: plot.id),
                    ),
                  );
                },
              ),
          if (member.isActive)
            PlotPickerField(
              label: 'Add plots',
              selectedIds: const [],
              onChanged: (ids) => _assignPlots(context, ref, member, ids),
            )
          else
            const Text(
              'Activate this member to give plots.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                _InfoRow(
                  label: 'Created',
                  value: _formatDate(member.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Delete (alag aur lal)
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref, member),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: const BorderSide(color: _red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Delete member',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
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

class _MemberPlotTile extends StatelessWidget {
  const _MemberPlotTile({required this.plot, required this.onTap});

  final Plot plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = plot.status.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: BlockBadge(
          code: plot.block,
          color: color,
          size: 42,
          filled: true,
          radius: 12,
        ),
        title: Text(
          plot.plotNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text('${plot.marlaText}  |  ${plot.priceText}'),
        trailing: StatusChip(status: plot.status),
      ),
    );
  }
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