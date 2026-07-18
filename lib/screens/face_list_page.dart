import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/face_data.dart';
import 'face_capture_page.dart';

class FaceListPage extends StatefulWidget {
  const FaceListPage({Key? key}) : super(key: key);

  @override
  State<FaceListPage> createState() => _FaceListPageState();
}

class _FaceListPageState extends State<FaceListPage> {
  List<FaceData> faces = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFaces();
  }

  Future<void> _fetchFaces() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Pengguna belum login.");
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('faces')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        faces = snapshot.docs.map((doc) => FaceData.fromFirestore(doc)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Gagal memuat data wajah: $e";
        isLoading = false;
      });
    }
  }

  void _confirmDelete(FaceData face) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Wajah'),
          content: Text('Apakah Anda yakin ingin menghapus wajah ${face.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFace(face);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFace(FaceData face) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.8:5000/delete-face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': face.name}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (face.imageUrl.isNotEmpty) {
            try {
              Reference storageRef = FirebaseStorage.instance.refFromURL(face.imageUrl);
              await storageRef.delete();
            } catch (e) {
              debugPrint('Gagal hapus file storage: $e');
            }
          }

          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('faces')
                .doc(face.id)
                .delete();
          }

          if (mounted) {
            Navigator.pop(context); // Tutup loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wajah berhasil dihapus.')),
            );
          }
          _fetchFaces();
        } else {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Gagal menghapus wajah')),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error server: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Wajah'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FaceCapturePage(),
            ),
          );
          // Refresh list after returning from capture page
          _fetchFaces();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Wajah'),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFaces,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (faces.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchFaces,
      child: _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchFaces,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Icon(
            Icons.face,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada wajah yang terdaftar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan wajah agar sistem dapat melakukan Face Recognition.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: faces.length,
      itemBuilder: (context, index) {
        final face = faces[index];
        String dateStr = 'Belum ada tanggal';
        if (face.createdAt != null) {
          dateStr = DateFormat('dd MMM yyyy, HH:mm').format(face.createdAt!);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: face.imageUrl.isNotEmpty 
                  ? NetworkImage(face.imageUrl) 
                  : null,
              child: face.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
              onBackgroundImageError: face.imageUrl.isNotEmpty
                  ? (exception, stackTrace) {
                      // Placeholder if image fails to load (managed implicitly by not throwing, 
                      // but we could also add a placeholder handling via a builder, for simplicity CircleAvatar handles it decently)
                    }
                  : null,
            ),
            title: Text(
              face.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(face),
            ),
          ),
        );
      },
    );
  }
}
