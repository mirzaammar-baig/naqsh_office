import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naqsh_office/features/history/history_log.dart';
import 'package:naqsh_office/features/history/plot_event.dart';

// Plot ki history parhne ka kaam.
class HistoryRepository {
  HistoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String societyId = 'demo-city';

  final FirebaseFirestore _db;

  // Live list, sab se naya kaam sab se oopar.
  Stream<List<PlotEvent>> watchPlotHistory(String plotId) {
    return HistoryLog.of(_db, societyId, plotId).snapshots().map((snapshot) {
      final events = [
        for (final doc in snapshot.docs)
          PlotEvent(
            id: doc.id,
            type: (doc.data()['type'] as String?) ?? '',
            title: (doc.data()['title'] as String?) ?? '',
            detail: (doc.data()['detail'] as String?) ?? '',
            by: (doc.data()['by'] as String?) ?? '',
            createdAt: doc.data()['createdAt'] is Timestamp
                ? (doc.data()['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ),
      ];
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    });
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

// Ek plot ki history (plotId dene par).
final plotHistoryProvider = StreamProvider.family<List<PlotEvent>, String>((
    ref,
    plotId,
    ) {
  return ref.read(historyRepositoryProvider).watchPlotHistory(plotId);
});