import 'package:naqsh_office/features/plots/plot_details.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

class Plot {
  const Plot({
    required this.id,
    required this.societyId,
    required this.block,
    required this.plotNumber,
    required this.widthFeet,
    required this.lengthFeet,
    required this.category,
    required this.isCorner,
    required this.status,
    required this.pricePaisa,
    this.details = const PlotDetails(),
  });

  final String id;
  final String societyId;
  final String block;
  final String plotNumber;
  final double widthFeet;
  final double lengthFeet;
  final String category;
  final bool isCorner;
  final PlotStatus status;
  final int pricePaisa;

  // Extra tafseel: description, facing, utilities, tags, faasle wagera.
  final PlotDetails details;

  // Demo City ke liye 1 Marla = 225 sqft
  static const int sqftPerMarla = 225;

  // Derived values: ye form mein type nahi hoti, khud calculate hoti hain.
  int get areaSqft => (widthFeet * lengthFeet).round();

  double get marla => areaSqft / sqftPerMarla;

  String get marlaText => '${formatNumber(marla)} Marla';

  String get dimensionsText =>
      '${formatNumber(widthFeet)} x ${formatNumber(lengthFeet)} ft';

  String get areaText => '${formatWithCommas(areaSqft)} sqft';

  String get priceText => 'Rs ${formatWithCommas(pricePaisa ~/ 100)}';

  String get cornerText => isCorner ? 'Yes' : 'No';

  // Sirf wohi cheezein badal sakte hain jo edit ho sakti hain.
  // id, societyId, block aur plotNumber locked hain.
  Plot copyWith({
    double? widthFeet,
    double? lengthFeet,
    String? category,
    bool? isCorner,
    PlotStatus? status,
    int? pricePaisa,
    PlotDetails? details,
  }) {
    return Plot(
      id: id,
      societyId: societyId,
      block: block,
      plotNumber: plotNumber,
      widthFeet: widthFeet ?? this.widthFeet,
      lengthFeet: lengthFeet ?? this.lengthFeet,
      category: category ?? this.category,
      isCorner: isCorner ?? this.isCorner,
      status: status ?? this.status,
      pricePaisa: pricePaisa ?? this.pricePaisa,
      details: details ?? this.details,
    );
  }
}

// 25.0 ko "25" likhta hai, 22.5 ko "22.5".
String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

// 2500000 ko "2,500,000" likhta hai.
String formatWithCommas(int number) {
  final digits = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}