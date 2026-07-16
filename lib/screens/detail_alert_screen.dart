import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/firestore_service.dart';

class DetailAlertScreen extends StatefulWidget {
  final AlertModel alert;

  const DetailAlertScreen({super.key, required this.alert});

  @override
  State<DetailAlertScreen> createState() => _DetailAlertScreenState();
}

class _DetailAlertScreenState extends State<DetailAlertScreen> {
  @override
  void initState() {
    super.initState();
    // Jika belum dibaca, tandai menjadi sudah dibaca di backend Firestore
    if (!widget.alert.read) {
      FirestoreService().markAsRead(widget.alert.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format nilai confidence
    final confidencePercent = widget.alert.confidence <= 1.0 
        ? (widget.alert.confidence * 100).toInt() 
        : widget.alert.confidence.toInt();

    // Format tanggal
    String formattedDate = '-';
    if (widget.alert.createdAt != null) {
      formattedDate = DateFormat('dd MMM yyyy HH:mm').format(widget.alert.createdAt!);
    }

    final isDanger = widget.alert.status == 'danger';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Alert'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Gambar
            Card(
              clipBehavior: Clip.antiAlias,
              child: widget.alert.imageUrl.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: const [
                          Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada gambar bukti',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      widget.alert.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: const [
                            Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            
            // Area Informasi Detail
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Chip(
                          avatar: Icon(
                            isDanger ? Icons.warning : Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            widget.alert.status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: isDanger ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.alert.message, style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$confidencePercent%', style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Waktu Deteksi', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(formattedDate, style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Status Read', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        widget.alert.read ? 'Sudah Dibaca' : 'Belum Dibaca (Ditandai dibaca sekarang)',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
