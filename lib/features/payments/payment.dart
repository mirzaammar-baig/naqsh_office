import 'package:naqsh_office/features/plots/plot.dart';

enum PaymentMethod {
  cash('Cash'),
  bankTransfer('Bank transfer'),
  cheque('Cheque'),
  online('Online (Easypaisa/JazzCash)');

  const PaymentMethod(this.label);

  final String label;
}

// Jaise: 13 Nov 2026
String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class Payment {
  const Payment({
    required this.id,
    required this.societyId,
    required this.plotId,
    required this.plotNumber,
    required this.memberId,
    required this.memberName,
    required this.receiptNo,
    required this.amountPaisa,
    required this.method,
    required this.createdAt,
    this.reference = '',
    this.note = '',
    this.createdBy = '',
    this.isReversed = false,
    this.reverseReason = '',
    this.reversedAt,
    this.isEarnest = false,
  });

  final String id;
  final String societyId;
  final String plotId;
  final String plotNumber;
  final String memberId;

  // Receipt ke waqt ka naam (baad mein member ka naam badle to receipt wahi rehti hai).
  final String memberName;
  final String receiptNo;
  final int amountPaisa;
  final PaymentMethod method;
  final DateTime createdAt;

  // Cheque number ya transaction ID (khali ho sakta hai).
  final String reference;
  final String note;
  final String createdBy;

  // Reverse ki hui payment hisab mein nahi ginte.
  final bool isReversed;
  final String reverseReason;
  final DateTime? reversedAt;
  // Booking ke waqt di gayi pehli raqam (earnest).
  final bool isEarnest;

  String get amountText => 'Rs ${formatWithCommas(amountPaisa ~/ 100)}';

  String get dateText => formatDate(createdAt);
}

// Ek plot par kul kitna diya gaya (reverse ki hui payments shamil nahi).
// Ek plot par kul kitna diya gaya (reverse ki hui payments shamil nahi).
// memberId do to sirf usi member ki payments ginti hain.
int paidPaisaForPlot(
    List<Payment> payments,
    String plotId, {
      String? memberId,
    }) {
  var total = 0;
  for (final payment in payments) {
    if (payment.plotId == plotId &&
        !payment.isReversed &&
        (memberId == null || payment.memberId == memberId)) {
      total += payment.amountPaisa;
    }
  }
  return total;
}