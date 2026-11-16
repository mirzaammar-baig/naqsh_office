import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naqsh_office/features/auth/auth_repository.dart';

// Plot ki history likhne ke madadgaar.
// Path: societies/<society>/plots/<plotId>/history
class HistoryLog {
  static CollectionReference<Map<String, dynamic>> of(
      FirebaseFirestore db,
      String societyId,
      String plotId,
      ) {
    return db
        .collection('societies')
        .doc(societyId)
        .collection('plots')
        .doc(plotId)
        .collection('history');
  }

  // Ek event ka data. 'by' mein login user ki email khud aati hai.
  static Map<String, dynamic> event({
    required String type,
    required String title,
    String detail = '',
  }) {
    return {
      'type': type,
      'title': title,
      'detail': detail,
      'by': AuthRepository().currentUser?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}