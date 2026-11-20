import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naqsh_office/features/history/history_log.dart';
import 'package:naqsh_office/features/members/member.dart';
import 'package:naqsh_office/features/members/plot_booking.dart';
import 'package:naqsh_office/features/payments/payment.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

// Firestore mein members parhne/likhne ka kaam yahin hota hai.
// Path: societies/demo-city/members
class FirestoreMemberRepository {
  FirestoreMemberRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String societyId = 'demo-city';

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _society =>
      _db.collection('societies').doc(societyId);

  CollectionReference<Map<String, dynamic>> get _members =>
      _society.collection('members');

  CollectionReference<Map<String, dynamic>> get _plots =>
      _society.collection('plots');

  CollectionReference<Map<String, dynamic>> get _payments =>
      _society.collection('payments');

  // Live list: Firestore mein jab bhi badlao ho, app khud update hoti hai.
  Stream<List<Member>> watchMembers() {
    return _members.snapshots().map((snapshot) {
      final members = [
        for (final doc in snapshot.docs) _memberFromMap(doc.id, doc.data()),
      ];
      members.sort((a, b) => a.memberNo.compareTo(b.memberNo));
      return members;
    });
  }

  // Naya member bhi aur edit bhi (id wahi to purana document badal jata hai).
  Future<void> saveMember(Member member) {
    return _members.doc(member.id).set(_memberToMap(member));
  }

  // Activate / purana tareeqa: sirf isActive badalta hai.
  Future<void> setActive(String id, bool value) {
    return _members.doc(id).update({'isActive': value});
  }

  // Naya member banao aur chune hue plots do.
  // Earnest wale plot Booked (receipt ke saath), baaqi Hold.
  // Sab ek transaction mein. Earnest ki receipt numbers wapas milte hain.
  Future<List<String>> addMemberWithPlots(
      Member member,
      List<PlotBooking> bookings, {
        required String by,
        int holdDays = 3,
      }) {
    return _db.runTransaction<List<String>>((transaction) async {
      final read = await _readBookings(transaction, bookings);

      transaction.set(_members.doc(member.id), _memberToMap(member));
      return _writeBookings(
        transaction,
        memberId: member.id,
        memberName: member.fullName,
        memberNo: member.memberNo,
        bookings: bookings,
        numbers: read.numbers,
        lastReceipt: read.last,
        by: by,
        holdDays: holdDays,
      );
    });
  }

  // Maujooda member ko aur plots do (wahi earnest ka rule).
  Future<List<String>> assignPlots(
      String memberId,
      List<PlotBooking> bookings, {
        required String by,
        int holdDays = 3,
      }) {
    return _db.runTransaction<List<String>>((transaction) async {
      final read = await _readBookings(transaction, bookings);

      final memberSnapshot = await transaction.get(_members.doc(memberId));
      final data = memberSnapshot.data();
      if (data == null) {
        throw StateError('Member not found.');
      }

      return _writeBookings(
        transaction,
        memberId: memberId,
        memberName: (data['fullName'] as String?) ?? '',
        memberNo: (data['memberNo'] as String?) ?? '',
        bookings: bookings,
        numbers: read.numbers,
        lastReceipt: read.last,
        by: by,
        holdDays: holdDays,
      );
    });
  }

  // Member ko inactive karo aur uske sab plots wapas Available kar do.
  Future<void> deactivateMember(String memberId) async {
    final name = await _memberName(memberId);
    final plots = await _plots.where('memberId', isEqualTo: memberId).get();
    final batch = _db.batch();

    batch.update(_members.doc(memberId), {'isActive': false});
    _releaseAll(batch, plots, 'Member $name was deactivated');

    await batch.commit();
  }

  // Member hamesha ke liye mita do aur uske sab plots wapas Available kar do.
  Future<void> deleteMember(String memberId) async {
    final name = await _memberName(memberId);
    final plots = await _plots.where('memberId', isEqualTo: memberId).get();
    final batch = _db.batch();

    batch.delete(_members.doc(memberId));
    _releaseAll(batch, plots, 'Member $name was deleted');

    await batch.commit();
  }

  Future<String> _memberName(String memberId) async {
    final snapshot = await _members.doc(memberId).get();
    return (snapshot.data()?['fullName'] as String?) ?? '';
  }

  // Sab plots Available, memberId khali, aur har ki history mein wajah.
  void _releaseAll(
      WriteBatch batch,
      QuerySnapshot<Map<String, dynamic>> plots,
      String reason,
      ) {
    for (final doc in plots.docs) {
      batch.update(doc.reference, {
        'status': PlotStatus.available.name,
        'memberId': null,
        'holdUntil': null,
      });
      batch.set(
        HistoryLog.of(_db, societyId, doc.id).doc(),
        HistoryLog.event(
          type: 'released',
          title: 'Plot released',
          detail: reason,
        ),
      );
    }
  }

  // ---------- Booking ke madadgaar ----------

  // Transaction ka pehla hissa: sirf parhna. Plot Available ho, earnest price
  // se zyada na ho, aur receipt counter ki maujooda value.
  Future<({Map<String, String> numbers, int last})> _readBookings(
      Transaction transaction,
      List<PlotBooking> bookings,
      ) async {
    final numbers = <String, String>{};
    for (final booking in bookings) {
      final snapshot = await transaction.get(_plots.doc(booking.plotId));
      final data = snapshot.data();
      final number = (data?['plotNumber'] as String?) ?? booking.plotId;
      if (data == null || data['status'] != PlotStatus.available.name) {
        throw StateError('Plot $number is no longer available.');
      }
      final price = ((data['pricePaisa'] as num?) ?? 0).toInt();
      if (booking.earnestPaisa > price) {
        throw StateError('Earnest for plot $number is more than its price.');
      }
      numbers[booking.plotId] = number;
    }

    var last = 0;
    if (bookings.any((b) => b.earnestPaisa > 0)) {
      final counter = await transaction.get(
        _society.collection('counters').doc('receipts'),
      );
      last = (counter.data()?['last'] as num?)?.toInt() ?? 0;
    }
    return (numbers: numbers, last: last);
  }

  // Transaction ka doosra hissa: sirf likhna.
  List<String> _writeBookings(
      Transaction transaction, {
        required String memberId,
        required String memberName,
        required String memberNo,
        required List<PlotBooking> bookings,
        required Map<String, String> numbers,
        required int lastReceipt,
        required String by,
        required int holdDays,
      }) {
    final label = '$memberName ($memberNo)';
    final now = DateTime.now();
    final holdUntil = DateTime(now.year, now.month, now.day + holdDays, 23, 59);
    final receipts = <String>[];
    var last = lastReceipt;

    for (final booking in bookings) {
      final number = numbers[booking.plotId]!;
      final plotRef = _plots.doc(booking.plotId);
      final history = HistoryLog.of(_db, societyId, booking.plotId);

      if (booking.earnestPaisa > 0) {
        last++;
        final receiptNo = 'R-${last.toString().padLeft(4, '0')}';
        receipts.add(receiptNo);
        final amountText = 'Rs ${formatWithCommas(booking.earnestPaisa ~/ 100)}';

        transaction.update(plotRef, {
          'status': PlotStatus.booked.name,
          'memberId': memberId,
          'holdUntil': null,
        });
        transaction.set(_payments.doc(), {
          'societyId': societyId,
          'plotId': booking.plotId,
          'plotNumber': number,
          'memberId': memberId,
          'memberName': memberName,
          'receiptNo': receiptNo,
          'amountPaisa': booking.earnestPaisa,
          'method': booking.method.name,
          'reference': booking.reference,
          'note': 'Earnest (booking amount)',
          'isEarnest': true,
          'createdBy': by,
          'isReversed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(
          history.doc(),
          HistoryLog.event(
            type: 'booked',
            title: 'Plot booked',
            detail: label,
          ),
        );
        transaction.set(
          history.doc(),
          HistoryLog.event(
            type: 'payment',
            title: 'Earnest received',
            detail:
            '$receiptNo - $amountText by ${booking.method.label} from $memberName',
          ),
        );
      } else {
        transaction.update(plotRef, {
          'status': PlotStatus.hold.name,
          'memberId': memberId,
          'holdUntil': Timestamp.fromDate(holdUntil),
        });
        transaction.set(
          history.doc(),
          HistoryLog.event(
            type: 'hold',
            title: 'Plot put on hold (no earnest)',
            detail: '$label, until ${formatDate(holdUntil)}',
          ),
        );
      }
    }

    if (receipts.isNotEmpty) {
      transaction.set(_society.collection('counters').doc('receipts'), {
        'last': last,
      });
    }
    return receipts;
  }

  // ---------- Member <-> Map ----------

  Map<String, dynamic> _memberToMap(Member member) {
    return {
      'societyId': member.societyId,
      'memberNo': member.memberNo,
      'fullName': member.fullName,
      'relationType': member.relationType,
      'relationName': member.relationName,
      'cnic': member.cnic,
      'phone': member.phone,
      'email': member.email,
      'address': member.address,
      'city': member.city,
      'isOverseas': member.isOverseas,
      'isActive': member.isActive,
      'createdAt': Timestamp.fromDate(member.createdAt),
    };
  }

  Member _memberFromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return Member(
      id: id,
      societyId: (data['societyId'] as String?) ?? societyId,
      memberNo: (data['memberNo'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? '',
      relationType: (data['relationType'] as String?) ?? 'S/O',
      relationName: (data['relationName'] as String?) ?? '',
      cnic: (data['cnic'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      isOverseas: (data['isOverseas'] as bool?) ?? false,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}