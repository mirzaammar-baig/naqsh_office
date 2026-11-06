import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/plots/block.dart';
import 'package:naqsh_office/features/plots/fake_plot_repository.dart';
import 'package:naqsh_office/features/plots/plot.dart';

// Data kahan se aata hai (abhi fake, baad mein Firestore).
final plotRepositoryProvider = Provider<FakePlotRepository>((ref) {
  return FakePlotRepository();
});

class PlotsState {
  const PlotsState({required this.plots, required this.blocks});

  final List<Plot> plots;
  final List<Block> blocks;

  PlotsState copyWith({List<Plot>? plots, List<Block>? blocks}) {
    return PlotsState(
      plots: plots ?? this.plots,
      blocks: blocks ?? this.blocks,
    );
  }
}

class PlotsNotifier extends Notifier<PlotsState> {
  @override
  PlotsState build() {
    final plots = ref.read(plotRepositoryProvider).getPlots();

    // Blocks fake plots se nikalo (A, B, C).
    final codes = <String>[];
    for (final plot in plots) {
      if (!codes.contains(plot.block)) {
        codes.add(plot.block);
      }
    }
    final blocks = [
      for (final code in codes) Block(code: code, societyId: 'demo-city'),
    ];

    return PlotsState(plots: plots, blocks: blocks);
  }

  bool blockExists(String code) {
    final clean = code.trim().toUpperCase();
    return state.blocks.any((block) => block.code == clean);
  }

  void addBlock(String code) {
    final block = Block(
      code: code.trim().toUpperCase(),
      societyId: 'demo-city',
    );
    state = state.copyWith(blocks: [...state.blocks, block]);
  }

  // plotNumber poora hota hai, jaise 'B-07'.
  bool plotExists(String plotNumber) {
    return state.plots.any((plot) => plot.plotNumber == plotNumber);
  }

  void addPlot(Plot plot) {
    state = state.copyWith(plots: [...state.plots, plot]);
  }

  void updatePlot(Plot updated) {
    state = state.copyWith(
      plots: [
        for (final plot in state.plots)
          if (plot.id == updated.id) updated else plot,
      ],
    );
  }
}

final plotsProvider = NotifierProvider<PlotsNotifier, PlotsState>(
  PlotsNotifier.new,
);