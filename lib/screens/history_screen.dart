import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';
import 'detail_alert_screen.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _firestoreService.getAlerts(),
        builder: (context, snapshot) {
          // 4. Menampilkan CircularProgressIndicator saat loading.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 6. Jika terjadi error tampilkan: "Terjadi kesalahan"
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          // 5. Menampilkan pesan: "Belum ada riwayat deteksi" jika collection kosong.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat deteksi'),
            );
          }

          final alerts = snapshot.data!;

          // 3. Menampilkan ListView jika data ada.
          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              
              // Format confidence agar dapat menyesuaikan jika bernilai 0.xx atau puluhan (xx)
              final confidencePercent = alert.confidence <= 1.0 
                  ? (alert.confidence * 100).toInt() 
                  : alert.confidence.toInt();

              // Format createdAt menggunakan package intl
              String formattedDate = '-';
              if (alert.createdAt != null) {
                formattedDate = DateFormat('dd MMM yyyy HH:mm').format(alert.createdAt!);
              }

              return ListTile(
                leading: Icon(
                  alert.status == 'danger' ? Icons.warning : Icons.check_circle,
                  color: alert.status == 'danger' ? Colors.red : Colors.green,
                ),
                title: Text(alert.message),
                subtitle: Text('Confidence : $confidencePercent%\n$formattedDate'),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailAlertScreen(alert: alert),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
