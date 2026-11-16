import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/auth/auth_repository.dart';
import 'package:naqsh_office/features/payments/firestore_payment_repository.dart';
import 'package:naqsh_office/features/payments/payment.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

final paymentRepositoryProvider = Provider<FirestorePaymentRepository>((ref) {
  return FirestorePaymentRepository();
});

class PaymentsNotifier extends Notifier<List<Payment>> {
  @override
  List<Payment> build() {
    final repository = ref.read(paymentRepositoryProvider);

    // Firestore mein payments badlein to state khud update ho jati hai.
    final subscription = repository.watchPayments().listen((payments) {
      state = payments;
    });

    ref.onDispose(subscription.cancel);

    return const [];
  }

  // Ek plot par ab tak kitna diya gaya.
  // Ek plot par ab tak kitna diya gaya (memberId do to sirf us member ka).
  int paidFor(String plotId, {String? memberId}) =>
      paidPaisaForPlot(state, plotId, memberId: memberId);

  // Payment likho. Receipt number wapas milta hai (jaise R-0001).
  Future<String> addPayment({
    required Plot plot,
    required String memberName,
    required int amountPaisa,
    required PaymentMethod method,
    String reference = '',
    String note = '',
  }) {
    final memberId = plot.memberId;

    if (memberId == null ||
        (plot.status != PlotStatus.booked &&
            plot.status != PlotStatus.allotted &&
            plot.status != PlotStatus.possession)) {
      throw StateError('Payments can only be added to a booked plot.');
    }
    if (amountPaisa <= 0) {
      throw StateError('Amount must be more than 0.');
    }

    final balance = plot.pricePaisa - paidFor(plot.id, memberId: memberId);
    if (amountPaisa > balance) {
      throw StateError(
        'Amount is more than the balance (Rs ${formatWithCommas(balance ~/ 100)}).',
      );
    }

    return ref
        .read(paymentRepositoryProvider)
        .addPayment(
      plotId: plot.id,
      plotNumber: plot.plotNumber,
      memberId: memberId,
      memberName: memberName,
      amountPaisa: amountPaisa,
      method: method,
      reference: reference.trim(),
      note: note.trim(),
      by: AuthRepository().currentUser?.email ?? '',
    );
  }

  Future<void> reversePayment(Payment payment, String reason) {
    if (payment.isReversed) {
      throw StateError('This payment is already reversed.');
    }
    return ref
        .read(paymentRepositoryProvider)
        .reversePayment(
      payment: payment,
      reason: reason.trim(),
      by: AuthRepository().currentUser?.email ?? '',
    );
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

// Dashboard ke liye (Step 16): kul wasool hui raqam aur baaqi raqam.
final totalCollectedPaisaProvider = Provider<int>((ref) {
  var total = 0;
  for (final payment in ref.watch(paymentsProvider)) {
    if (!payment.isReversed) {
      total += payment.amountPaisa;
    }
  }
  return total;
});