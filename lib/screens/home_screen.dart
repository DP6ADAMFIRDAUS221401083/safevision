import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'face_list_page.dart';
import '../services/firestore_service.dart';
import '../models/alert_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Setelah signOut berhasil, AuthGate akan mendeteksi perubahan stream
    // dan otomatis mengembalikan layar ke LoginScreen.
  }

  void _showProfileDialog(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${userData['name'] ?? 'Tidak ada nama'}'),
            const SizedBox(height: 8),
            Text('Email: ${userData['email'] ?? 'Tidak ada email'}'),
            const SizedBox(height: 8),
            Text('Role: ${userData['role'] ?? 'Tidak ada role'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _openHistoryPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(),
      ),
    );
  }

  void _openFaceListPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceListPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text('SAFEVISION'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.error),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text('Tidak ada pengguna yang login', style: theme.textTheme.bodyLarge))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan saat memuat data', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('Data pengguna tidak ditemukan', style: theme.textTheme.bodyLarge));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String name = userData['name'] ?? 'Pengguna';
                final String email = userData['email'] ?? 'Tidak ada email';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sapaan
                      Text(
                        'Halo, ${name.toUpperCase()}',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 32),

                      // Status Sistem
                      _buildStatusCard(
                        context,
                        title: 'Status Sistem',
                        value: 'Aktif & Aman',
                        icon: Icons.check_circle_outline,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(height: 32),

                      // Statistik
                      Text(
                        'Ringkasan Sistem',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<AlertModel>>(
                        stream: FirestoreService().getAlerts(),
                        builder: (context, alertSnapshot) {
                          int notifToday = 0;
                          int detectionToday = 0;
                          int dangerToday = 0;
                          
                          if (alertSnapshot.hasData) {
                            final alerts = alertSnapshot.data!;
                            final now = DateTime.now();
                            for (var alert in alerts) {
                              if (alert.createdAt != null) {
                                if (alert.createdAt!.year == now.year &&
                                    alert.createdAt!.month == now.month &&
                                    alert.createdAt!.day == now.day) {
                                  notifToday++;
                                  detectionToday++;
                                }
                              }
                              if (alert.status == 'danger') {
                                dangerToday++;
                              }
                            }
                          }

                          return GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.2,
                            children: [
                              _buildStatCard(
                                context,
                                title: 'Pemberitahuan',
                                value: notifToday.toString(),
                                color: theme.colorScheme.secondary,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Deteksi',
                                value: detectionToday.toString(),
                                color: theme.primaryColor,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Peringatan',
                                value: dangerToday.toString(),
                                color: theme.colorScheme.error,
                              ),
                              Card(
                                child: InkWell(
                                  onTap: () => _showProfileDialog(context, userData),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person, size: 32, color: theme.textTheme.bodyLarge?.color),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Profil',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 32),

                      // Tombol Riwayat & Daftar Wajah
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openHistoryPage(context),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Riwayat Deteksi'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openFaceListPage(context),
                          icon: const Icon(Icons.face, size: 18),
                          label: const Text('Daftar Wajah'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: color.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall,
            ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontFamily: 'Space Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
