import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

class _BlockSpec {
  const _BlockSpec(
      this.block,
      this.widthFeet,
      this.lengthFeet,
      this.pricePaisa,
      this.statuses,
      );

  final String block;
  final int widthFeet;
  final int lengthFeet;
  final int pricePaisa;
  final List<PlotStatus> statuses;
}

class FakePlotRepository {
  List<Plot> getPlots() => _buildPlots();
}

List<Plot> _buildPlots() {
  const specs = [
    _BlockSpec('A', 15, 45, 150000000, [
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.hold,
      PlotStatus.booked,
      PlotStatus.booked,
      PlotStatus.allotted,
      PlotStatus.allotted,
      PlotStatus.possession,
    ]),
    _BlockSpec('B', 25, 45, 250000000, [
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.hold,
      PlotStatus.booked,
      PlotStatus.booked,
      PlotStatus.allotted,
      PlotStatus.allotted,
      PlotStatus.blocked,
    ]),
    _BlockSpec('C', 45, 50, 500000000, [
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.available,
      PlotStatus.hold,
      PlotStatus.booked,
      PlotStatus.booked,
      PlotStatus.allotted,
      PlotStatus.possession,
      PlotStatus.blocked,
    ]),
  ];

  final plots = <Plot>[];

  for (final spec in specs) {
    for (var i = 1; i <= 10; i++) {
      final number = i.toString().padLeft(2, '0');
      final plotNumber = '${spec.block}-$number';

      plots.add(
        Plot(
          id: plotNumber.toLowerCase(),
          societyId: 'demo-city',
          block: spec.block,
          plotNumber: plotNumber,
          widthFeet: spec.widthFeet.toDouble(),
          lengthFeet: spec.lengthFeet.toDouble(),
          category: (spec.block == 'C' && i >= 9) ? 'Commercial' : 'Residential',
          isCorner: i == 10,
          status: spec.statuses[i - 1],
          pricePaisa: spec.pricePaisa,
        ),
      );
    }
  }

  return plots;
}