import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil daftar alert milik user yang sedang login secara real-time.
  Stream<List<AlertModel>> getAlerts() {
    try {
      final String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User belum terautentikasi.');
      }

      print('Listening Firestore stream...');
      return _db
          .collection('alerts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('New alert received');
            print('Total alerts: ${snapshot.docs.length}');
            return snapshot.docs
                .map((doc) => AlertModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      print('Error di getAlerts: $e');
      return const Stream.empty();
    }
  }

  /// Menandai spesifik alert menjadi telah dibaca (read: true).
  Future<void> markAsRead(String alertId) async {
    try {
      await _db.collection('alerts').doc(alertId).update({
        'read': true,
      });
    } catch (e) {
      print('Error di markAsRead: $e');
      rethrow;
    }
  }

  /// Mengambil satu dokumen alert secara tunggal (bukan stream) berdasarkan alertId.
  Future<AlertModel?> getAlert(String alertId) async {
    try {
      final docSnapshot = await _db.collection('alerts').doc(alertId).get();

      if (docSnapshot.exists) {
        return AlertModel.fromFirestore(docSnapshot);
      } else {
        return null; // Dokumen tidak ditemukan
      }
    } catch (e) {
      print('Error di getAlert: $e');
      rethrow;
    }
  }
}
