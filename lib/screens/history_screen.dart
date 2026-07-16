import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';
import 'detail_alert_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Key _streamKey = UniqueKey();

  void _retry() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
      ),
      body: StreamBuilder<List<AlertModel>>(
        key: _streamKey,
        stream: _firestoreService.getAlerts(),
        builder: (context, snapshot) {
          Widget content;

          if (snapshot.connectionState == ConnectionState.waiting) {
            content = Center(
              key: const ValueKey('loading'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat riwayat...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            content = Center(
              key: const ValueKey('error'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Terjadi kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tidak dapat mengambil data.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            content = Center(
              key: const ValueKey('empty'),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada riwayat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Riwayat deteksi akan muncul setelah sistem AI mendeteksi aktivitas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          } else {
            final alerts = snapshot.data!;
            content = ListView.builder(
              key: const ValueKey('data'),
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
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: content,
          );
        },
      ),
    );
  }
}
