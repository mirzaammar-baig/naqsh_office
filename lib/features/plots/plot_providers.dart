import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/plots/block.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';

// 1. Saare plots (ab Notifier se, jo badalte rehte hain).
final allPlotsProvider = Provider<List<Plot>>((ref) {
  return ref.watch(plotsProvider).plots;
});

// 2. Saare blocks.
final blocksProvider = Provider<List<Block>>((ref) {
  return ref.watch(plotsProvider).blocks;
});

// 3. Search box ka text.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final searchQueryProvider =
NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// 4. Block filter: 'All' ya kisi block ka code.
class BlockFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setBlock(String value) {
    state = value;
  }
}

final blockFilterProvider =
NotifierProvider<BlockFilterNotifier, String>(BlockFilterNotifier.new);

// 5. Status filter: null ka matlab 'All'.
class StatusFilterNotifier extends Notifier<PlotStatus?> {
  @override
  PlotStatus? build() => null;

  void setStatus(PlotStatus? value) {
    state = value;
  }
}

final statusFilterProvider =
NotifierProvider<StatusFilterNotifier, PlotStatus?>(
  StatusFilterNotifier.new,
);

// 6. Search aur dono filters lagne ke baad bachne wale plots.
final filteredPlotsProvider = Provider<List<Plot>>((ref) {
  final plots = ref.watch(allPlotsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final block = ref.watch(blockFilterProvider);
  final status = ref.watch(statusFilterProvider);

  return plots.where((plot) {
    final matchesSearch =
        query.isEmpty || plot.plotNumber.toLowerCase().contains(query);
    final matchesBlock = block == 'All' || plot.block == block;
    final matchesStatus = status == null || plot.status == status;
    return matchesSearch && matchesBlock && matchesStatus;
  }).toList();
});

// 7. Dashboard ke liye har status ke kitne plots hain.
final plotStatusCountsProvider = Provider<Map<PlotStatus, int>>((ref) {
  final plots = ref.watch(allPlotsProvider);
  return {
    for (final status in PlotStatus.values)
      status: plots.where((plot) => plot.status == status).length,
  };
});

// 8. Har block mein kitne plots hain (Manage Blocks screen ke liye).
final blockPlotCountsProvider = Provider<Map<String, int>>((ref) {
  final plots = ref.watch(allPlotsProvider);
  final blocks = ref.watch(blocksProvider);
  return {
    for (final block in blocks)
      block.code: plots.where((plot) => plot.block == block.code).length,
  };
});