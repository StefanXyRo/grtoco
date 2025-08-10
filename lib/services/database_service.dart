import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/report.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportItem({
    required String itemId,
    required String itemType,
    required String reporterId,
    String? reason,
  }) async {
    // Adaugă un raport în colecția 'reports'
    await _firestore.collection('reports').add({
      'itemId': itemId,
      'itemType': itemType,
      'reporterId': reporterId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Incrementează reportCount pentru postare sau comentariu
    final itemRef = _firestore.collection('${itemType}s').doc(itemId);
    final itemDoc = await itemRef.get();

    if (itemDoc.exists) {
      int currentReportCount = itemDoc.data()?['reportCount'] ?? 0;
      int newReportCount = currentReportCount + 1;

      await itemRef.update({'reportCount': newReportCount});

      // Marchează item-ul ca 'flagged' dacă atinge pragul
      if (newReportCount >= 5) {
        await itemRef.update({'isFlagged': true});
      }
    }
  }
}
