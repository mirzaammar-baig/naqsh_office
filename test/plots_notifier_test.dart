import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';
import 'package:naqsh_office/features/plots/plots_notifier.dart';

void main() {
  group('PlotsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with blocks A, B, C and 30 plots', () {
      final state = container.read(plotsProvider);
      expect(state.blocks.map((block) => block.code).toList(), ['A', 'B', 'C']);
      expect(state.plots.length, 30);
    });

    test('addBlock adds a new block', () {
      final notifier = container.read(plotsProvider.notifier);
      expect(notifier.blockExists('A'), isTrue);
      expect(notifier.blockExists('D'), isFalse);

      notifier.addBlock('d');

      expect(notifier.blockExists('D'), isTrue);
      expect(container.read(plotsProvider).blocks.length, 4);
    });

    test('addPlot adds a plot and plotExists finds it', () {
      final notifier = container.read(plotsProvider.notifier);
      expect(notifier.plotExists('D-01'), isFalse);

      notifier.addPlot(
        const Plot(
          id: 'd-01',
          societyId: 'demo-city',
          block: 'D',
          plotNumber: 'D-01',
          widthFeet: 30,
          lengthFeet: 45,
          category: 'Residential',
          isCorner: false,
          status: PlotStatus.available,
          pricePaisa: 300000000,
        ),
      );

      expect(notifier.plotExists('D-01'), isTrue);
      expect(container.read(plotsProvider).plots.length, 31);
    });

    test('updatePlot changes only that plot', () {
      final notifier = container.read(plotsProvider.notifier);
      final original = container.read(plotsProvider).plots.first;

      notifier.updatePlot(original.copyWith(pricePaisa: 160000000));

      final plots = container.read(plotsProvider).plots;
      final updated = plots.firstWhere((plot) => plot.id == original.id);
      expect(updated.priceText, 'Rs 1,600,000');
      expect(plots.length, 30);
    });
  });
}