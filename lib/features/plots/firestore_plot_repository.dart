import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naqsh_office/features/history/history_log.dart';
import 'package:naqsh_office/features/payments/payment.dart';
import 'package:naqsh_office/features/plots/block.dart';
import 'package:naqsh_office/features/plots/plot.dart';
import 'package:naqsh_office/features/plots/plot_details.dart';
import 'package:naqsh_office/features/plots/plot_status.dart';

// Firestore mein plots aur blocks parhne/likhne ka kaam yahin hota hai.
// Path: societies/demo-city/plots aur societies/demo-city/blocks
class FirestorePlotRepository {
  FirestorePlotRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String societyId = 'demo-city';

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _society =>
      _db.collection('societies').doc(societyId);

  CollectionReference<Map<String, dynamic>> get _plots =>
      _society.collection('plots');

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _society.collection('blocks');

  // ---------- Parhna (live) ----------

  Stream<List<Plot>> watchPlots() {
    return _plots.snapshots().map((snapshot) {
      final plots = [
        for (final doc in snapshot.docs) _plotFromMap(doc.id, doc.data()),
      ];
      plots.sort((a, b) => a.plotNumber.compareTo(b.plotNumber));
      return plots;
    });
  }

  Stream<List<Block>> watchBlocks() {
    return _blocks.snapshots().map((snapshot) {
      final blocks = [
        for (final doc in snapshot.docs)
          Block(
            code: doc.id,
            societyId: (doc.data()['societyId'] as String?) ?? societyId,
            description: (doc.data()['description'] as String?) ?? '',
          ),
      ];
      blocks.sort((a, b) => a.code.compareTo(b.code));
      return blocks;
    });
  }

  // ---------- Likhna ----------

  Future<void> addBlock(Block block) {
    return _blocks.doc(block.code).set({
      'code': block.code,
      'societyId': block.societyId,
      'description': block.description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  // Block mein koi plot hai ya nahi.
  Future<bool> _blockHasPlots(String code) async {
    final result = await _plots.where('block', isEqualTo: code).limit(1).get();
    return result.docs.isNotEmpty;
  }

  // Sirf description badalna (hamesha mumkin).
  Future<void> updateBlockDescription(String code, String description) {
    return _blocks.doc(code).update({'description': description.trim()});
  }

  // Naam badalna: sirf khali block ka (warna plot ids toot jate hain).
  Future<void> renameEmptyBlock(
      String oldCode,
      String newCode,
      String description,
      ) async {
    if (await _blockHasPlots(oldCode)) {
      throw StateError(
        'Block $oldCode has plots, so its name cannot be changed.',
      );
    }
    final exists = await _blocks.doc(newCode).get();
    if (exists.exists) {
      throw StateError('Block $newCode already exists.');
    }

    final batch = _db.batch();
    batch.delete(_blocks.doc(oldCode));
    batch.set(_blocks.doc(newCode), {
      'code': newCode,
      'societyId': societyId,
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // Delete: sirf khali block.
  Future<void> deleteBlock(String code) async {
    if (await _blockHasPlots(code)) {
      throw StateError(
        'Block $code still has plots. Remove or move them first.',
      );
    }
    await _blocks.doc(code).delete();
  }

  // Naya plot (isNew true) ya edit (isNew false). Dono ki history likhi jati hai.
  Future<void> savePlot(Plot plot, {required bool isNew}) {
    final batch = _db.batch();

    batch.set(_plots.doc(plot.id), _plotToMap(plot));
    batch.set(
      HistoryLog.of(_db, societyId, plot.id).doc(),
      HistoryLog.event(
        type: isNew ? 'created' : 'edited',
        title: isNew ? 'Plot created' : 'Plot edited',
        detail: '${plot.plotNumber} - ${plot.marlaText}, ${plot.priceText}',
      ),
    );

    return batch.commit();
  }

  Future<void> deletePlot(String plotId) {
    return _plots.doc(plotId).delete();
  }

  // ---------- Status badalna (sab ki history likhi jati hai) ----------

  // Hold: Available plot member ke naam par aakhri tareekh tak roko.
  Future<void> holdPlot(String plotId, String memberId, DateTime until) {
    return _db.runTransaction((transaction) async {
      final plotRef = _plots.doc(plotId);
      final snapshot = await transaction.get(plotRef);
      final data = snapshot.data();
      if (data == null || data['status'] != PlotStatus.available.name) {
        final name = (data?['plotNumber'] as String?) ?? plotId;
        throw StateError('Plot $name is no longer available.');
      }

      final memberName = await _memberNameOf(transaction, memberId);

      transaction.update(plotRef, {
        'status': PlotStatus.hold.name,
        'memberId': memberId,
        'holdUntil': Timestamp.fromDate(until),
      });
      transaction.set(
        HistoryLog.of(_db, societyId, plotId).doc(),
        HistoryLog.event(
          type: 'hold',
          title: 'Plot put on hold',
          detail: '$memberName, until ${formatDate(until)}',
        ),
      );
    });
  }

  // Hold se Booked (member wahi rehta hai).
  Future<void> bookHeldPlot(String plotId) {
    return _transition(
      plotId,
      allowedFrom: [PlotStatus.hold],
      changes: {'status': PlotStatus.booked.name, 'holdUntil': null},
      type: 'booked',
      title: (from) => 'Plot booked',
    );
  }

  // Booked se Allotted (member ne paise de diye).
  Future<void> allotPlot(String plotId) {
    return _transition(
      plotId,
      allowedFrom: [PlotStatus.booked],
      changes: {'status': PlotStatus.allotted.name},
      type: 'allotted',
      title: (from) => 'Plot allotted',
    );
  }

  // Allotted se Possession.
  Future<void> startPossession(String plotId) {
    return _transition(
      plotId,
      allowedFrom: [PlotStatus.allotted],
      changes: {'status': PlotStatus.possession.name},
      type: 'possession',
      title: (from) => 'Possession given',
    );
  }

  // Available plot ko Blocked karo.
  Future<void> blockPlot(String plotId) {
    return _transition(
      plotId,
      allowedFrom: [PlotStatus.available],
      changes: {'status': PlotStatus.blocked.name},
      type: 'blocked',
      title: (from) => 'Plot blocked',
    );
  }

  // Hold release, Booking cancel ya Unblock: plot wapas Available.
  Future<void> releasePlot(String plotId) {
    return _transition(
      plotId,
      allowedFrom: [PlotStatus.hold, PlotStatus.booked, PlotStatus.blocked],
      changes: {
        'status': PlotStatus.available.name,
        'memberId': null,
        'holdUntil': null,
      },
      type: 'released',
      title: (from) {
        if (from == PlotStatus.hold.name) {
          return 'Hold released';
        }
        if (from == PlotStatus.booked.name) {
          return 'Booking cancelled';
        }
        return 'Plot unblocked';
      },
    );
  }

  // Ek jaisa tareeqa: plot ka maujooda status check karo, badlo, history likho.
  Future<void> _transition(
      String plotId, {
        required List<PlotStatus> allowedFrom,
        required Map<String, dynamic> changes,
        required String type,
        required String Function(String from) title,
      }) {
    return _db.runTransaction((transaction) async {
      final plotRef = _plots.doc(plotId);
      final snapshot = await transaction.get(plotRef);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Plot not found.');
      }

      final from = (data['status'] as String?) ?? '';
      final plotNumber = (data['plotNumber'] as String?) ?? plotId;
      if (!allowedFrom.any((status) => status.name == from)) {
        throw StateError(
          'Plot $plotNumber is now $from, so this action is not possible.',
        );
      }

      final memberName = await _memberNameOf(
        transaction,
        data['memberId'] as String?,
      );

      transaction.update(plotRef, changes);
      transaction.set(
        HistoryLog.of(_db, societyId, plotId).doc(),
        HistoryLog.event(type: type, title: title(from), detail: memberName),
      );
    });
  }

  Future<String> _memberNameOf(Transaction transaction, String? memberId) async {
    if (memberId == null) {
      return '';
    }
    final snapshot = await transaction.get(
      _society.collection('members').doc(memberId),
    );
    return (snapshot.data()?['fullName'] as String?) ?? '';
  }

  // ---------- Plot <-> Map ----------

  Map<String, dynamic> _plotToMap(Plot plot) {
    return {
      'societyId': plot.societyId,
      'block': plot.block,
      'plotNumber': plot.plotNumber,
      'widthFeet': plot.widthFeet,
      'lengthFeet': plot.lengthFeet,
      'category': plot.category,
      'isCorner': plot.isCorner,
      'status': plot.status.name,
      'pricePaisa': plot.pricePaisa,
      'details': plot.details.toMap(),
      'memberId': plot.memberId,
      'holdUntil': plot.holdUntil == null
          ? null
          : Timestamp.fromDate(plot.holdUntil!),
    };
  }

  Plot _plotFromMap(String id, Map<String, dynamic> data) {
    final statusName = data['status'] as String?;
    return Plot(
      id: id,
      societyId: (data['societyId'] as String?) ?? societyId,
      block: (data['block'] as String?) ?? '',
      plotNumber: (data['plotNumber'] as String?) ?? '',
      widthFeet: ((data['widthFeet'] as num?) ?? 0).toDouble(),
      lengthFeet: ((data['lengthFeet'] as num?) ?? 0).toDouble(),
      category: (data['category'] as String?) ?? 'Residential',
      isCorner: (data['isCorner'] as bool?) ?? false,
      status: PlotStatus.values.firstWhere(
            (status) => status.name == statusName,
        orElse: () => PlotStatus.available,
      ),
      pricePaisa: ((data['pricePaisa'] as num?) ?? 0).toInt(),
      details: data['details'] is Map
          ? PlotDetails.fromMap(
        Map<String, dynamic>.from(data['details'] as Map),
      )
          : const PlotDetails(),
      memberId: data['memberId'] as String?,
      holdUntil: data['holdUntil'] is Timestamp
          ? (data['holdUntil'] as Timestamp).toDate()
          : null,
    );
  }
}