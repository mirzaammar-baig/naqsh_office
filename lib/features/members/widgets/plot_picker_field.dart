import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_providers.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

// Member form mein: sirf Available plots dikhata hai, ek ya zyada chuno.
class PlotPickerField extends ConsumerWidget {
  const PlotPickerField({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.label = 'Plots (optional)',
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String label;

  Future<void> _openSheet(BuildContext context, List<Plot> available) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _PlotPickerSheet(available: available, initial: selectedIds);
      },
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sirf wo plots jo Available hain aur kisi member ke paas nahi.
    final available = [
      for (final plot in ref.watch(allPlotsProvider))
        if (plot.status == PlotStatus.available && plot.memberId == null) plot,
    ]..sort((a, b) => a.plotNumber.compareTo(b.plotNumber));

    final selectedPlots = [
      for (final plot in available)
        if (selectedIds.contains(plot.id)) plot,
    ];

    final totalPaisa = selectedPlots.fold<int>(
      0,
          (sum, plot) => sum + plot.pricePaisa,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedPlots.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final plot in selectedPlots)
                InputChip(
                  label: Text('${plot.plotNumber} - ${plot.marlaText}'),
                  onDeleted: () {
                    onChanged([
                      for (final id in selectedIds)
                        if (id != plot.id) id,
                    ]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total price: Rs ${formatWithCommas(totalPaisa ~/ 100)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: available.isEmpty
                ? null
                : () => _openSheet(context, available),
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(
              available.isEmpty
                  ? 'No available plots'
                  : selectedPlots.isEmpty
                  ? 'Select plots (${available.length} available)'
                  : 'Change plots (${available.length} available)',
            ),
          ),
        ),
        if (selectedPlots.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Add earnest below to confirm the booking.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

class _PlotPickerSheet extends StatefulWidget {
  const _PlotPickerSheet({required this.available, required this.initial});

  final List<Plot> available;
  final List<String> initial;

  @override
  State<_PlotPickerSheet> createState() => _PlotPickerSheetState();
}

class _PlotPickerSheetState extends State<_PlotPickerSheet> {
  final TextEditingController searchController = TextEditingController();
  late final Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = {...widget.initial};
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = [
      for (final plot in widget.available)
        if (query.isEmpty ||
            plot.plotNumber.toLowerCase().contains(query) ||
            plot.marlaText.toLowerCase().contains(query))
          plot,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Available plots',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${selected.length} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search plot number or size',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No plots found'))
                  : ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final plot = visible[index];
                  return CheckboxListTile(
                    value: selected.contains(plot.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selected.add(plot.id);
                        } else {
                          selected.remove(plot.id);
                        }
                      });
                    },
                    title: Text(
                      plot.plotNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${plot.marlaText}  |  ${plot.dimensionsText}  |  ${plot.priceText}',
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, selected.toList()),
                    child: Text('Done (${selected.length} selected)'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}