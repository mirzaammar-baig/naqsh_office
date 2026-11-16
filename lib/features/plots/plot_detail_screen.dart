import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/member_detail_screen.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_form_screen.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';
import 'package:naqsh_office/features/plots/widgets/plot_details_view.dart';
import 'package:naqsh_office/features/plots/widgets/status_chip.dart';
import 'package:naqsh_office/features/history/plot_history_screen.dart';
import 'package:naqsh_office/features/payments/widgets/plot_payments_section.dart';
import 'package:naqsh_office/features/members/widgets/book_plots_sheet.dart';
import 'package:naqsh_office/features/plots/widgets/block_badge.dart';

const Color _red = Color(0xFFDC2626);
const Color _green = Color(0xFF16A34A);
const Color _amber = Color(0xFFD97706);
const Color _grey = Color(0xFF6B7280);

class PlotDetailScreen extends ConsumerWidget {
  const PlotDetailScreen({super.key, required this.plotId});

  final String plotId;

  // ---------- Chhote madadgaar ----------

  void _showError(ScaffoldMessengerState messenger, Object error) {
    String text;
    if (error is TimeoutException) {
      text = 'Could not reach the server. Check your internet and try again.';
    } else if (error is StateError) {
      text = error.message;
    } else {
      text = 'Something went wrong: $error';
    }
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  // Kaam chalao (10 second tak), phir success ya error ka message dikhao.
  Future<void> _run(
      ScaffoldMessengerState messenger,
      Future<void> Function() task,
      String success,
      ) async {
    try {
      await task().timeout(const Duration(seconds: 10));
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      _showError(messenger, error);
    }
  }

  Future<bool> _confirm(
      BuildContext context, {
        required String title,
        required String message,
        required String action,
        Color color = AppColors.primary,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // ---------- Kaam (actions) ----------

  Future<void> _delete(BuildContext context, WidgetRef ref, Plot plot) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);

    final ok = await _confirm(
      context,
      title: 'Delete ${plot.plotNumber}?',
      message: 'This plot will be removed permanently. This cannot be undone.',
      action: 'Delete',
      color: _red,
    );
    if (!ok) {
      return;
    }

    navigator.pop();
    await _run(
      messenger,
          () => notifier.deletePlot(plot.id),
      'Plot ${plot.plotNumber} deleted',
    );
  }

  // Available plot: member chuno, earnest do (Booked) ya bina earnest Hold.
  Future<void> _bookOrHold(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    final members = [
      for (final member in ref.read(membersProvider))
        if (member.isActive) member,
    ]..sort((a, b) => a.memberNo.compareTo(b.memberNo));

    if (members.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add an active member first.')),
      );
      return;
    }

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return BookPlotsSheet(
          title: 'Book or hold ${plot.plotNumber}',
          plotIds: [plot.id],
          members: members,
        );
      },
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _book(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      Member? owner,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);
    final who = owner?.fullName ?? 'the member';

    final ok = await _confirm(
      context,
      title: 'Book ${plot.plotNumber}?',
      message: '${plot.plotNumber} will be marked Booked for $who.',
      action: 'Book',
      color: AppColors.primary,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.bookHeldPlot(plot.id),
      'Plot ${plot.plotNumber} booked',
    );
  }

  Future<void> _allot(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      Member? owner,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);
    final who = owner?.fullName ?? 'this member';

    final ok = await _confirm(
      context,
      title: 'Allot ${plot.plotNumber}?',
      message:
      '${plot.plotNumber} will be marked Allotted to $who. '
          'Do this when the payment has been received.',
      action: 'Allot',
      color: _green,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.allotPlot(plot.id),
      'Plot ${plot.plotNumber} allotted',
    );
  }

  Future<void> _possession(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      Member? owner,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);
    final who = owner?.fullName ?? 'the member';

    final ok = await _confirm(
      context,
      title: 'Give possession of ${plot.plotNumber}?',
      message:
      'Possession of ${plot.plotNumber} will be given to $who. '
          'This is the final step.',
      action: 'Give possession',
      color: _green,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.startPossession(plot.id),
      'Possession given for ${plot.plotNumber}',
    );
  }

  // Hold ya Booking cancel: plot wapas Available.
  Future<void> _release(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      Member? owner,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);
    final who = owner?.fullName ?? 'the member';
    final isHold = plot.status == PlotStatus.hold;

    final ok = await _confirm(
      context,
      title: isHold
          ? 'Release hold on ${plot.plotNumber}?'
          : 'Cancel booking of ${plot.plotNumber}?',
      message:
      '${isHold ? 'The hold' : 'The booking'} for $who will be cancelled '
          'and ${plot.plotNumber} will become Available again.',
      action: isHold ? 'Release hold' : 'Cancel booking',
      color: _red,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.releasePlot(plot.id),
      'Plot ${plot.plotNumber} is Available again',
    );
  }

  Future<void> _block(BuildContext context, WidgetRef ref, Plot plot) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);

    final ok = await _confirm(
      context,
      title: 'Block ${plot.plotNumber}?',
      message:
      '${plot.plotNumber} will be blocked and cannot be given to anyone '
          'until you unblock it.',
      action: 'Block',
      color: _grey,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.blockPlot(plot.id),
      'Plot ${plot.plotNumber} blocked',
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref, Plot plot) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(plotsProvider.notifier);

    final ok = await _confirm(
      context,
      title: 'Unblock ${plot.plotNumber}?',
      message: '${plot.plotNumber} will become Available again.',
      action: 'Unblock',
      color: _green,
    );
    if (!ok) {
      return;
    }
    await _run(
      messenger,
          () => notifier.releasePlot(plot.id),
      'Plot ${plot.plotNumber} is Available again',
    );
  }

  // ---------- Buttons ----------

  Widget _button({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return Expanded(
      child: SizedBox(
        height: 52,
        child: filled
            ? FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            shape: shape,
          ),
          icon: Icon(icon, size: 20),
          label: Text(label, style: textStyle),
        )
            : OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            shape: shape,
          ),
          icon: Icon(icon, size: 20),
          label: Text(label, style: textStyle),
        ),
      ),
    );
  }

  Widget _row(List<Widget> buttons) {
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          buttons[i],
        ],
      ],
    );
  }

  // Neeche ki bar: plot ke status ke hisaab se alag buttons.
  Widget _bottomBar(
      BuildContext context,
      WidgetRef ref,
      Plot plot,
      Member? owner,
      ) {
    switch (plot.status) {
      case PlotStatus.available:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row([
              _button(
                label: 'Edit Plot',
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                filled: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlotFormScreen(plot: plot),
                    ),
                  );
                },
              ),
              _button(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                color: _red,
                onPressed: () => _delete(context, ref, plot),
              ),
            ]),
            const SizedBox(height: 10),
            _row([
              _button(
                label: 'Book / Hold',
                icon: Icons.bookmark_add_outlined,
                color: AppColors.primary,
                onPressed: () => _bookOrHold(context, ref, plot),
              ),
              _button(
                label: 'Block',
                icon: Icons.block_rounded,
                color: _grey,
                onPressed: () => _block(context, ref, plot),
              ),
            ]),
          ],
        );
      case PlotStatus.hold:
        return _row([
          _button(
            label: 'Book',
            icon: Icons.bookmark_added_outlined,
            color: AppColors.primary,
            filled: true,
            onPressed: () => _book(context, ref, plot, owner),
          ),
          _button(
            label: 'Release',
            icon: Icons.undo_rounded,
            color: _red,
            onPressed: () => _release(context, ref, plot, owner),
          ),
        ]);
      case PlotStatus.booked:
        return _row([
          _button(
            label: 'Allot Plot',
            icon: Icons.verified_outlined,
            color: _green,
            filled: true,
            onPressed: () => _allot(context, ref, plot, owner),
          ),
          _button(
            label: 'Cancel',
            icon: Icons.undo_rounded,
            color: _red,
            onPressed: () => _release(context, ref, plot, owner),
          ),
        ]);
      case PlotStatus.allotted:
        return _row([
          _button(
            label: 'Give Possession',
            icon: Icons.key_rounded,
            color: _green,
            filled: true,
            onPressed: () => _possession(context, ref, plot, owner),
          ),
        ]);
      case PlotStatus.blocked:
        return _row([
          _button(
            label: 'Unblock',
            icon: Icons.lock_open_rounded,
            color: _green,
            filled: true,
            onPressed: () => _unblock(context, ref, plot),
          ),
          _button(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            color: _red,
            onPressed: () => _delete(context, ref, plot),
          ),
        ]);
      case PlotStatus.possession:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 16, color: _green),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Possession given. No further actions.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ],
        );
    }
  }

  // Status ke upar chhota sa message (Hold ki tareekh, Blocked ki wazahat).
  Widget? _banner(Plot plot) {
    if (plot.status == PlotStatus.hold) {
      final expired = plot.isHoldExpired;
      return _Banner(
        color: expired ? _red : _amber,
        icon: expired ? Icons.warning_amber_rounded : Icons.schedule_rounded,
        text: expired
            ? 'Hold expired on ${plot.holdUntilText}. Release it or book it.'
            : 'On hold until ${plot.holdUntilText}.',
      );
    }
    if (plot.status == PlotStatus.blocked) {
      return const _Banner(
        color: _grey,
        icon: Icons.block_rounded,
        text: 'This plot is blocked. Unblock it to make it available.',
      );
    }
    return null;
  }

  String _ownerLabel(PlotStatus status) {
    return switch (status) {
      PlotStatus.hold => 'On hold for',
      PlotStatus.booked => 'Booked by',
      PlotStatus.allotted => 'Allotted to',
      PlotStatus.possession => 'In possession of',
      _ => 'Member',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Taaza plot Notifier se dhoondo, taake edit ke baad detail update ho.
    final matches = ref.watch(allPlotsProvider).where((p) => p.id == plotId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plot Detail')),
        body: const Center(child: Text('Plot not found')),
      );
    }
    final plot = matches.first;

    // Plot ka maalik member (agar hai).
    final ownerId = plot.memberId;
    final owner = ownerId == null
        ? null
        : ref
        .watch(membersProvider)
        .where((m) => m.id == ownerId)
        .firstOrNull;

    final color = plot.status.color;
    final banner = _banner(plot);

    return Scaffold(
      appBar: AppBar(title: const Text('Plot Detail')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _bottomBar(context, ref, plot, owner),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BlockBadge(
                      code: plot.block,
                      color: color,
                      size: 56,
                      filled: true,
                      radius: 18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plot.plotNumber,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusChip(status: plot.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plot.priceText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (banner != null) ...[banner, const SizedBox(height: 16)],

          // Maalik (member)
          if (owner != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                _ownerLabel(plot.status),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            _OwnerCard(
              member: owner,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MemberDetailScreen(memberId: owner.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Payments (sirf Booked/Allotted/Possession plots par nazar aate hain)
          PlotPaymentsSection(plot: plot, memberName: owner?.fullName ?? ''),

          // History (har plot ki timeline)
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlotHistoryScreen(
                      plotId: plot.id,
                      plotNumber: plot.plotNumber,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('View history'),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Plot information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 112,
            ),
            children: [
              _InfoTile(
                icon: Icons.grid_view_rounded,
                label: 'Block',
                value: plot.block,
              ),
              _InfoTile(
                icon: Icons.square_foot_outlined,
                label: 'Size',
                value: plot.marlaText,
              ),
              _InfoTile(
                icon: Icons.straighten_outlined,
                label: 'Dimensions',
                value: plot.dimensionsText,
              ),
              _InfoTile(
                icon: Icons.aspect_ratio_rounded,
                label: 'Area',
                value: plot.areaText,
              ),
              _InfoTile(
                icon: Icons.home_work_outlined,
                label: 'Category',
                value: plot.category,
              ),
              _InfoTile(
                icon: Icons.near_me_outlined,
                label: 'Corner',
                value: plot.cornerText,
              ),
            ],
          ),
          const SizedBox(height: 24),
          PlotDetailsView(details: plot.details),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.member, required this.onTap});

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            member.initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text('${member.memberNo}  |  ${member.phone}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}