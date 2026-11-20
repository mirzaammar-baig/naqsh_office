import 'package:naqsh_office/features/payments/payment.dart';

// Add Member mein ek chune hue plot ki booking: earnest ke saath ya bina.
class PlotBooking {
  const PlotBooking({
    required this.plotId,
    this.earnestPaisa = 0,
    this.method = PaymentMethod.cash,
    this.reference = '',
  });

  final String plotId;

  // 0 ho to earnest nahi diya (plot Hold hoga).
  final int earnestPaisa;
  final PaymentMethod method;
  final String reference;
}