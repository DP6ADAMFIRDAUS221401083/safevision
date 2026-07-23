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

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeVision'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Tidak ada pengguna yang login'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan saat memuat data'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Data pengguna tidak ditemukan'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String name = userData['name'] ?? 'Pengguna';
                final String email = userData['email'] ?? 'Tidak ada email';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sapaan
                      Text(
                        'Selamat Datang, $name',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Status Sistem
                      _buildStatusCard(
                        context,
                        title: 'Status Sistem',
                        value: 'Online',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),

                      // Statistik
                      const Text(
                        'Ringkasan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            children: [
                              _buildStatCard(
                                context,
                                title: 'Notifikasi Hari Ini',
                                value: notifToday.toString(),
                                icon: Icons.notifications,
                                color: Colors.blue,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Deteksi Hari Ini',
                                value: detectionToday.toString(),
                                icon: Icons.remove_red_eye,
                                color: Colors.orange,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Kejadian Berbahaya',
                                value: dangerToday.toString(),
                                icon: Icons.warning,
                                color: Colors.red,
                              ),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: InkWell(
                                  onTap: () => _showProfileDialog(context, userData),
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person, size: 40, color: Colors.purple),
                                        SizedBox(height: 8),
                                        Text(
                                          'Profil',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold),
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

                      // Tombol Riwayat, Daftar Wajah, & Logout
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openHistoryPage(context),
                          icon: const Icon(Icons.history),
                          label: const Text('Riwayat Deteksi'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openFaceListPage(context),
                          icon: const Icon(Icons.face),
                          label: const Text('Daftar Wajah'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
