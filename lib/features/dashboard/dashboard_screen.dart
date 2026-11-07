import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/members_notifier.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(allPlotsProvider).length;
    final counts = ref.watch(plotStatusCountsProvider);
    final totalMembers = ref.watch(totalMembersProvider);
    final activeMembers = ref.watch(activeMembersProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TotalCard(total: total, counts: counts),
        const SizedBox(height: 24),
        const _SectionTitle('Plots by status'),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          children: [
            for (final status in PlotStatus.values)
              _StatCard(
                title: status.label,
                value: counts[status] ?? 0,
                color: status.color,
                icon: _iconFor(status),
                trailing: total == 0
                    ? '0%'
                    : '${((counts[status] ?? 0) * 100 / total).round()}%',
              ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Members'),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          children: [
            _StatCard(
              title: 'Total Members',
              value: totalMembers,
              color: AppColors.primary,
              icon: Icons.groups_rounded,
            ),
            _StatCard(
              title: 'Active Members',
              value: activeMembers,
              color: const Color(0xFF16A34A),
              icon: Icons.how_to_reg_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

IconData _iconFor(PlotStatus status) {
  return switch (status) {
    PlotStatus.available => Icons.check_circle_outline_rounded,
    PlotStatus.hold => Icons.pause_circle_outline_rounded,
    PlotStatus.booked => Icons.bookmark_border_rounded,
    PlotStatus.allotted => Icons.assignment_turned_in_outlined,
    PlotStatus.possession => Icons.key_rounded,
    PlotStatus.blocked => Icons.block_rounded,
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.counts});

  final int total;
  final Map<PlotStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Demo City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Total Plots',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          Text(
            '$total',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                spacing: 3,
                children: [
                  for (final status in PlotStatus.values)
                    if ((counts[status] ?? 0) > 0)
                      Expanded(
                        flex: counts[status]!,
                        child: Container(color: status.color),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.trailing,
  });

  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final String? trailing;

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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}