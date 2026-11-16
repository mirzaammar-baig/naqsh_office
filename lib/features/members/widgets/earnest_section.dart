import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_input_decoration.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/members/plot_booking.dart';
import 'package:naqsh_office/features/payments/payment.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';

const Color _green = Color(0xFF16A34A);
const Color _amber = Color(0xFFD97706);

String _rs(int paisa) => 'Rs ${formatWithCommas(paisa ~/ 100)}';

class _Entry {
  final TextEditingController amount = TextEditingController();
  final TextEditingController reference = TextEditingController();
  PaymentMethod method = PaymentMethod.cash;
  String? error;

  void dispose() {
    amount.dispose();
    reference.dispose();
  }
}

// Add Member mein: har chune hue plot ke liye earnest (booking amount).
// Earnest do to plot Booked, na do to Hold.
class EarnestSection extends ConsumerStatefulWidget {
  const EarnestSection({super.key, required this.plotIds, this.holdDays = 3});

  final List<String> plotIds;

  // Earnest na ho to plot kitne din Hold rahega (sirf likhne ke liye).
  final int holdDays;

  @override
  ConsumerState<EarnestSection> createState() => EarnestSectionState();
}

class EarnestSectionState extends ConsumerState<EarnestSection> {
  final Map<String, _Entry> entries = {};

  _Entry entryFor(String plotId) => entries.putIfAbsent(plotId, _Entry.new);

  @override
  void didUpdateWidget(covariant EarnestSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jo plot hata diye gaye, unke khane bhi hata do.
    final removed = [
      for (final id in entries.keys)
        if (!widget.plotIds.contains(id)) id,
    ];
    for (final id in removed) {
      entries.remove(id)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final entry in entries.values) {
      entry.dispose();
    }
    super.dispose();
  }

  // Save se pehle form screen isay bulati hai. Ghalti ho to null milta hai.
  List<PlotBooking>? collect() {
    final plots = ref.read(allPlotsProvider);
    var allValid = true;
    final result = <PlotBooking>[];

    for (final id in widget.plotIds) {
      final plot = plots.where((p) => p.id == id).firstOrNull;
      if (plot == null) {
        allValid = false;
        continue;
      }

      final entry = entryFor(id);
      final text = entry.amount.text.trim();
      final rupees = text.isEmpty ? 0 : int.tryParse(text);

      String? error;
      if (rupees == null) {
        error = 'Enter a valid amount';
      } else if (rupees * 100 > plot.pricePaisa) {
        error = 'More than the plot price (${_rs(plot.pricePaisa)})';
      }
      entry.error = error;

      if (error != null) {
        allValid = false;
      } else {
        result.add(
          PlotBooking(
            plotId: id,
            earnestPaisa: rupees! * 100,
            method: entry.method,
            reference: entry.reference.text.trim(),
          ),
        );
      }
    }

    setState(() {});
    return allValid ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    final plots = ref.watch(allPlotsProvider);
    final selected = [
      for (final id in widget.plotIds)
        if (plots.any((p) => p.id == id)) plots.firstWhere((p) => p.id == id),
    ];
    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }

    var totalEarnest = 0;
    for (final plot in selected) {
      final rupees = int.tryParse(entryFor(plot.id).amount.text.trim()) ?? 0;
      totalEarnest += rupees * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnest (booking amount)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Earnest dene par plot Booked ho jata hai. Earnest na ho to plot '
              '${widget.holdDays} din ke liye Hold hota hai.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        for (final plot in selected) _buildPlotCard(plot),
        if (totalEarnest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Total earnest: ${_rs(totalEarnest)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlotCard(Plot plot) {
    final entry = entryFor(plot.id);
    final rupees = int.tryParse(entry.amount.text.trim()) ?? 0;
    final hasEarnest = rupees > 0;
    final tooMuch = rupees * 100 > plot.pricePaisa;

    String helper;
    Color helperColor;
    if (!hasEarnest) {
      helper =
      'No earnest: plot will be on Hold for ${widget.holdDays} '
          'day${widget.holdDays == 1 ? '' : 's'}';
      helperColor = _amber;
    } else if (tooMuch) {
      helper = 'More than the plot price';
      helperColor = Colors.red;
    } else {
      helper =
      'Plot will be Booked. Balance after earnest: '
          '${_rs(plot.pricePaisa - rupees * 100)}';
      helperColor = _green;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plot.plotNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                plot.priceText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.amount,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: appInputDecoration(
              label: 'Earnest amount (Rs)',
              hint: 'Leave empty for Hold',
              prefixText: 'Rs ',
            ).copyWith(errorText: entry.error),
            onChanged: (_) {
              setState(() {
                entry.error = null;
              });
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final percent in const [5, 10, 20])
                ActionChip(
                  label: Text('$percent%'),
                  onPressed: () {
                    setState(() {
                      entry.amount.text =
                          (plot.pricePaisa * percent ~/ 10000).toString();
                      entry.error = null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: helperColor,
            ),
          ),
          if (hasEarnest && !tooMuch) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: entry.method == option,
                    onSelected: (_) {
                      setState(() {
                        entry.method = option;
                      });
                    },
                  ),
              ],
            ),
            if (entry.method != PaymentMethod.cash) ...[
              const SizedBox(height: 12),
              TextField(
                controller: entry.reference,
                style: const TextStyle(fontSize: 16),
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                decoration: appInputDecoration(
                  label: 'Reference / Cheque no. (optional)',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}