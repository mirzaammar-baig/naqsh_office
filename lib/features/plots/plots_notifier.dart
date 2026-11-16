import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/plots/block.dart';
import 'package:naqsh_office/features/plots/firestore_plot_repository.dart';
import 'package:naqsh_office/features/plots/plot.dart';

// Data ab Firestore se aata hai.
final plotRepositoryProvider = Provider<FirestorePlotRepository>((ref) {
  return FirestorePlotRepository();
});

class PlotsState {
  const PlotsState({
    required this.plots,
    required this.blocks,
    this.plotsLoaded = false,
    this.blocksLoaded = false,
    this.error,
  });

  final List<Plot> plots;
  final List<Block> blocks;
  final bool plotsLoaded;
  final bool blocksLoaded;
  final String? error;

  // Jab tak dono lists pehli baar nahi aatin, loading hai.
  bool get isLoading => !(plotsLoaded && blocksLoaded);

  PlotsState copyWith({
    List<Plot>? plots,
    List<Block>? blocks,
    bool? plotsLoaded,
    bool? blocksLoaded,
    String? error,
    bool clearError = false,
  }) {
    return PlotsState(
      plots: plots ?? this.plots,
      blocks: blocks ?? this.blocks,
      plotsLoaded: plotsLoaded ?? this.plotsLoaded,
      blocksLoaded: blocksLoaded ?? this.blocksLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlotsNotifier extends Notifier<PlotsState> {
  @override
  PlotsState build() {
    final repository = ref.read(plotRepositoryProvider);

    // Firestore mein jab bhi plots badlein, state khud update ho jati hai.
    final plotsSub = repository.watchPlots().listen(
          (plots) {
        state = state.copyWith(
          plots: plots,
          plotsLoaded: true,
          clearError: true,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          plotsLoaded: true,
          error: 'Could not load plots. Check your internet.',
        );
      },
    );

    final blocksSub = repository.watchBlocks().listen(
          (blocks) {
        state = state.copyWith(
          blocks: blocks,
          blocksLoaded: true,
          clearError: true,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          blocksLoaded: true,
          error: 'Could not load blocks. Check your internet.',
        );
      },
    );

    ref.onDispose(() {
      plotsSub.cancel();
      blocksSub.cancel();
    });

    return const PlotsState(plots: [], blocks: []);
  }

  bool blockExists(String code) {
    final clean = code.trim().toUpperCase();
    return state.blocks.any((block) => block.code == clean);
  }

  Future<void> addBlock(String code) {
    final block = Block(
      code: code.trim().toUpperCase(),
      societyId: FirestorePlotRepository.societyId,
    );
    return ref.read(plotRepositoryProvider).addBlock(block);
  }

  Future<void> editBlock({
    required Block block,
    required String newCode,
    required String description,
  }) {
    final repository = ref.read(plotRepositoryProvider);
    final clean = newCode.trim().toUpperCase();
    if (clean != block.code) {
      return repository.renameEmptyBlock(block.code, clean, description);
    }
    return repository.updateBlockDescription(block.code, description);
  }

  Future<void> deleteBlock(String code) {
    return ref.read(plotRepositoryProvider).deleteBlock(code);
  }

  // plotNumber poora hota hai, jaise 'B-07'.
  bool plotExists(String plotNumber) {
    return state.plots.any((plot) => plot.plotNumber == plotNumber);
  }

  Future<void> addPlot(Plot plot) {
    return ref.read(plotRepositoryProvider).savePlot(plot, isNew: true);
  }

  Future<void> updatePlot(Plot updated) {
    return ref.read(plotRepositoryProvider).savePlot(updated, isNew: false);
  }
  Future<void> deletePlot(String plotId) {
    return ref.read(plotRepositoryProvider).deletePlot(plotId);
  }
  Future<void> allotPlot(String plotId) {
    return ref.read(plotRepositoryProvider).allotPlot(plotId);
  }

  Future<void> releasePlot(String plotId) {
    return ref.read(plotRepositoryProvider).releasePlot(plotId);
  }
  Future<void> holdPlot(String plotId, String memberId, DateTime until) {
    return ref.read(plotRepositoryProvider).holdPlot(plotId, memberId, until);
  }

  Future<void> bookHeldPlot(String plotId) {
    return ref.read(plotRepositoryProvider).bookHeldPlot(plotId);
  }

  Future<void> startPossession(String plotId) {
    return ref.read(plotRepositoryProvider).startPossession(plotId);
  }

  Future<void> blockPlot(String plotId) {
    return ref.read(plotRepositoryProvider).blockPlot(plotId);
  }
}

final plotsProvider = NotifierProvider<PlotsNotifier, PlotsState>(
  PlotsNotifier.new,
);