import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';

class DetailAlertScreen extends StatefulWidget {
  final AlertModel? alert;
  final String? alertId;

  const DetailAlertScreen({super.key, this.alert, this.alertId});

  @override
  State<DetailAlertScreen> createState() => _DetailAlertScreenState();
}

class _DetailAlertScreenState extends State<DetailAlertScreen> {
  AlertModel? _alert;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.alert != null) {
      _alert = widget.alert;
      _markAsRead();
    } else if (widget.alertId != null) {
      _fetchAlert(widget.alertId!);
    } else {
      _errorMessage = 'Data tidak valid';
    }
  }

  void _markAsRead() {
    if (_alert != null && !_alert!.read) {
      FirestoreService().markAsRead(_alert!.id);
    }
  }

  Future<void> _fetchAlert(String id) async {
    setState(() => _isLoading = true);
    try {
      final fetchedAlert = await FirestoreService().getAlert(id);
      if (mounted) {
        setState(() {
          _alert = fetchedAlert;
          if (_alert == null) {
            _errorMessage = 'Alert tidak ditemukan';
          }
          _isLoading = false;
        });
        if (_alert != null) _markAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat alert';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Peringatan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Memuat Data...', style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Peringatan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi Kesalahan', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Kesalahan tidak diketahui', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    final alert = _alert!;

    final confidencePercent = alert.confidence <= 1.0 
        ? (alert.confidence * 100).toInt() 
        : alert.confidence.toInt();

    String formattedDate = '-';
    if (alert.createdAt != null) {
      formattedDate = DateFormat('dd MMM yyyy HH:mm:ss').format(alert.createdAt!);
    }

    final isDanger = alert.status == 'danger';
    final statusColor = isDanger ? theme.colorScheme.error : theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Peringatan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Gambar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.surface),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: alert.imageUrl.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'Gambar Tidak Tersedia',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                          )
                        : AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              alert.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text('Gagal Memuat Gambar', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Frame decorations
                  Positioned(
                    top: 10, left: 10,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(border: Border(top: BorderSide(color: statusColor, width: 2), left: BorderSide(color: statusColor, width: 2)))),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(border: Border(top: BorderSide(color: statusColor, width: 2), right: BorderSide(color: statusColor, width: 2)))),
                  ),
                  Positioned(
                    bottom: 10, left: 10,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: statusColor, width: 2), left: BorderSide(color: statusColor, width: 2)))),
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(width: 20, height: 20, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: statusColor, width: 2), right: BorderSide(color: statusColor, width: 2)))),
                  ),
                  // REC Badge
                  if (alert.imageUrl.isNotEmpty)
                    Positioned(
                      top: 14, right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('REKAM', style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Area Informasi Detail
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan Kejadian', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 24),
                    
                    _buildDetailRow(theme, 'Status', alert.status.toUpperCase(), valueColor: statusColor),
                    const Divider(height: 24),
                    
                    _buildDetailRow(theme, 'Klasifikasi', alert.message.toUpperCase()),
                    const Divider(height: 24),
                    
                    _buildDetailRow(theme, 'Akurasi', '$confidencePercent%'),
                    const Divider(height: 24),
                    
                    _buildDetailRow(theme, 'Waktu', formattedDate),
                    const Divider(height: 24),
                    
                    _buildDetailRow(theme, 'Status Laporan', alert.read ? 'Sudah Dibaca' : 'Belum Dibaca'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: 'Space Mono',
          color: valueColor ?? theme.textTheme.bodyLarge?.color,
        )),
      ],
    );
  }
}
