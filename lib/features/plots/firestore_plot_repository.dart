import 'package:cloud_firestore/cloud_firestore.dart';
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

  CollectionReference<Map<String, dynamic>> get _plots =>
      _db.collection('societies').doc(societyId).collection('plots');

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _db.collection('societies').doc(societyId).collection('blocks');

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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Naya plot bhi aur edit bhi: id wahi rahe to purana document badal jata hai.
  Future<void> savePlot(Plot plot) {
    return _plots.doc(plot.id).set(_plotToMap(plot));
  }
  Future<void> deletePlot(String plotId) {
    return _plots.doc(plotId).delete();
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
          ? PlotDetails.fromMap(Map<String, dynamic>.from(data['details'] as Map))
          : const PlotDetails(),
    );
  }
}