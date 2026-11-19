import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naqsh_office/features/payments/payment.dart';

// Payments ka Firestore wala hissa.
// Path: societies/demo-city/payments
// Receipt counter: societies/demo-city/counters/receipts
// History: societies/demo-city/plots/<plotId>/history
class FirestorePaymentRepository {
  FirestorePaymentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String societyId = 'demo-city';

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _society =>
      _db.collection('societies').doc(societyId);

  CollectionReference<Map<String, dynamic>> get _payments =>
      _society.collection('payments');

  CollectionReference<Map<String, dynamic>> _history(String plotId) =>
      _society.collection('plots').doc(plotId).collection('history');

  // Sab payments, nayi sab se oopar.
  Stream<List<Payment>> watchPayments() {
    return _payments.snapshots().map((snapshot) {
      final payments = [
        for (final doc in snapshot.docs) _fromMap(doc.id, doc.data()),
      ];
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return payments;
    });
  }

  // Nayi payment likho. Receipt number (R-0001...) transaction mein banta hai
  // taake kabhi do payments ka ek number na ho. Receipt number wapas milta hai.
  Future<String> addPayment({
    required String plotId,
    required String plotNumber,
    required String memberId,
    required String memberName,
    required int amountPaisa,
    required PaymentMethod method,
    required String reference,
    required String note,
    required String by,
  }) {
    return _db.runTransaction<String>((transaction) async {
      final counterRef = _society.collection('counters').doc('receipts');
      final counterSnapshot = await transaction.get(counterRef);
      final last = (counterSnapshot.data()?['last'] as num?)?.toInt() ?? 0;
      final next = last + 1;
      final receiptNo = 'R-${next.toString().padLeft(4, '0')}';

      transaction.set(counterRef, {'last': next});

      transaction.set(_payments.doc(), {
        'societyId': societyId,
        'plotId': plotId,
        'plotNumber': plotNumber,
        'memberId': memberId,
        'memberName': memberName,
        'receiptNo': receiptNo,
        'amountPaisa': amountPaisa,
        'method': method.name,
        'reference': reference,
        'note': note,
        'createdBy': by,
        'isReversed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // History mein bhi likho.
      final amountText = 'Rs ${(amountPaisa ~/ 100)}';
      transaction.set(_history(plotId).doc(), {
        'type': 'payment',
        'title': 'Payment received',
        'detail': '$receiptNo - $amountText by ${method.label} from $memberName',
        'by': by,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return receiptNo;
    });
  }

  // Payment reverse: mitati nahi, nishan lagati hai aur wajah likhti hai.
  Future<void> reversePayment({
    required Payment payment,
    required String reason,
    required String by,
  }) {
    final batch = _db.batch();

    batch.update(_payments.doc(payment.id), {
      'isReversed': true,
      'reverseReason': reason,
      'reversedBy': by,
      'reversedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_history(payment.plotId).doc(), {
      'type': 'payment_reversed',
      'title': 'Payment reversed',
      'detail': '${payment.receiptNo} (${payment.amountText}) reversed: $reason',
      'by': by,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return batch.commit();
  }

  Payment _fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final reversed = data['reversedAt'];
    final methodName = data['method'] as String?;

    return Payment(
      id: id,
      societyId: (data['societyId'] as String?) ?? societyId,
      plotId: (data['plotId'] as String?) ?? '',
      plotNumber: (data['plotNumber'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      memberName: (data['memberName'] as String?) ?? '',
      receiptNo: (data['receiptNo'] as String?) ?? '',
      amountPaisa: ((data['amountPaisa'] as num?) ?? 0).toInt(),
      method: PaymentMethod.values.firstWhere(
            (method) => method.name == methodName,
        orElse: () => PaymentMethod.cash,
      ),
      reference: (data['reference'] as String?) ?? '',
      note: (data['note'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      isReversed: (data['isReversed'] as bool?) ?? false,
      reverseReason: (data['reverseReason'] as String?) ?? '',
      reversedAt: reversed is Timestamp ? reversed.toDate() : null,
      isEarnest: (data['isEarnest'] as bool?) ?? false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}