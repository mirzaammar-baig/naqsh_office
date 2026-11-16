import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/history/history_repository.dart';
import 'package:naqsh_office/features/history/plot_event.dart';
import 'package:naqsh_office/features/payments/payment.dart';

// Plot ki poori timeline: kab kya hua aur kis ne kiya.
class PlotHistoryScreen extends ConsumerWidget {
  const PlotHistoryScreen({
    super.key,
    required this.plotId,
    required this.plotNumber,
  });

  final String plotId;
  final String plotNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(plotHistoryProvider(plotId));

    return Scaffold(
      appBar: AppBar(title: Text('History - $plotNumber')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load history. Check your internet.'),
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No history yet. Every change to this plot will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _TimelineItem(
                event: events[index],
                isLast: index == events.length - 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.isLast});

  final PlotEvent event;
  final bool isLast;

  (IconData, Color) get _look {
    return switch (event.type) {
      'created' => (Icons.add_circle_outline_rounded, AppColors.primary),
      'edited' => (Icons.edit_outlined, AppColors.primary),
      'hold' => (Icons.pause_circle_outline_rounded, const Color(0xFFD97706)),
      'booked' => (Icons.bookmark_added_outlined, AppColors.primary),
      'allotted' => (Icons.verified_outlined, const Color(0xFF16A34A)),
      'possession' => (Icons.key_rounded, const Color(0xFF16A34A)),
      'blocked' => (Icons.block_rounded, const Color(0xFF6B7280)),
      'released' => (Icons.undo_rounded, const Color(0xFFDC2626)),
      'payment' => (Icons.payments_outlined, const Color(0xFF16A34A)),
      'payment_reversed' => (Icons.replay_rounded, const Color(0xFFDC2626)),
      _ => (Icons.history_rounded, AppColors.textMuted),
    };
  }

  String get _timeText {
    final time = event.createdAt;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${formatDate(time)}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _look;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14101828),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (event.detail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.detail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      event.by.isEmpty ? _timeText : '$_timeText  |  ${event.by}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}