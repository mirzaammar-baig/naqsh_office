import 'package:flutter_test/flutter_test.dart';
import 'package:naqsh_office/features/plots/fake_plot_repository.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

Plot makePlot({
  double width = 25,
  double length = 45,
  int pricePaisa = 250000000,
}) {
  return Plot(
    id: 'b-03',
    societyId: 'demo-city',
    block: 'B',
    plotNumber: 'B-03',
    widthFeet: width,
    lengthFeet: length,
    category: 'Residential',
    isCorner: false,
    status: PlotStatus.available,
    pricePaisa: pricePaisa,
  );
}

void main() {
  group('Plot', () {
    test('area is width x length', () {
      expect(makePlot().areaSqft, 1125);
    });

    test('1125 sqft is 5 Marla', () {
      expect(makePlot().marlaText, '5 Marla');
    });

    test('decimal width: 22.5 x 40 is 900 sqft and 4 Marla', () {
      final plot = makePlot(width: 22.5, length: 40);
      expect(plot.areaSqft, 900);
      expect(plot.marlaText, '4 Marla');
      expect(plot.dimensionsText, '22.5 x 40 ft');
    });

    test('price text is made from paisa', () {
      expect(makePlot().priceText, 'Rs 2,500,000');
    });

    test('copyWith changes price but keeps locked fields', () {
      final updated = makePlot().copyWith(pricePaisa: 160000000);
      expect(updated.priceText, 'Rs 1,600,000');
      expect(updated.plotNumber, 'B-03');
      expect(updated.block, 'B');
    });
  });

  group('FakePlotRepository', () {
    test('has 30 plots', () {
      expect(FakePlotRepository().getPlots().length, 30);
    });

    test('status counts match the task', () {
      final plots = FakePlotRepository().getPlots();
      int count(PlotStatus status) {
        return plots.where((plot) => plot.status == status).length;
      }

      expect(count(PlotStatus.available), 12);
      expect(count(PlotStatus.hold), 3);
      expect(count(PlotStatus.booked), 6);
      expect(count(PlotStatus.allotted), 5);
      expect(count(PlotStatus.possession), 2);
      expect(count(PlotStatus.blocked), 2);
    });
  });
}