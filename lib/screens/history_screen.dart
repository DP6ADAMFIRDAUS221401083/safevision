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
    final theme = Theme.of(context);
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
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Memuat Data...', style: theme.textTheme.labelMedium),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            content = Center(
              key: const ValueKey('error'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 80, color: theme.colorScheme.error.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Terjadi Kesalahan', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
                  const SizedBox(height: 8),
                  Text('Tidak dapat memuat data.', style: theme.textTheme.bodySmall),
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
                  children: [
                    Icon(Icons.history_toggle_off, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text('Belum Ada Riwayat', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Riwayat peringatan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          } else {
            final alerts = snapshot.data!;
            content = ListView.builder(
              key: const ValueKey('data'),
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                
                final confidencePercent = alert.confidence <= 1.0 
                    ? (alert.confidence * 100).toInt() 
                    : alert.confidence.toInt();

                String formattedDate = '-';
                if (alert.createdAt != null) {
                  formattedDate = DateFormat('dd MMM yyyy HH:mm').format(alert.createdAt!);
                }

                final bool isDanger = alert.status == 'danger';
                final Color statusColor = isDanger ? theme.colorScheme.error : theme.primaryColor;
                final IconData statusIcon = isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: isDanger ? theme.colorScheme.error.withOpacity(0.5) : theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailAlertScreen(alert: alert),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.message.toUpperCase(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: isDanger ? theme.colorScheme.error : theme.textTheme.titleSmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.analytics_outlined, size: 14, color: theme.textTheme.bodySmall?.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AKURASI: $confidencePercent%',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: theme.textTheme.bodySmall?.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  ),
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
