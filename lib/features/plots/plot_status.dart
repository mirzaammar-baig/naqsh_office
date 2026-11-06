import 'package:flutter/material.dart';

enum PlotStatus {
  available('Available', Color(0xFF16A34A)),
  hold('On Hold', Color(0xFFF59E0B)),
  booked('Booked', Color(0xFF2563EB)),
  allotted('Allotted', Color(0xFF7C3AED)),
  possession('Possession', Color(0xFF0D9488)),
  blocked('Blocked', Color(0xFF6B7280));

  const PlotStatus(this.label, this.color);

  final String label;
  final Color color;
}