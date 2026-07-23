import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class FaceCapturePage extends StatefulWidget {
  const FaceCapturePage({Key? key}) : super(key: key);

  @override
  State<FaceCapturePage> createState() => _FaceCapturePageState();
}

class _FaceCapturePageState extends State<FaceCapturePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Cari kamera depan, jika tidak ada gunakan kamera pertama (biasanya belakang)
        CameraDescription selectedCamera = _cameras!.first;
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            selectedCamera = camera;
            break;
          }
        }

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerFace() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.8:5000/register-face'),
      );
      
      request.fields['name'] = name;
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _capturedImage!.path,
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              throw Exception("User belum login");
            }

            String uid = user.uid;
            String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
            String storagePath = 'faces/$uid/$timestamp.jpg';

            // Upload ke Firebase Storage
            File imageFile = File(_capturedImage!.path);
            Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
            UploadTask uploadTask = storageRef.putFile(imageFile);
            TaskSnapshot snapshot = await uploadTask;
            String imageUrl = await snapshot.ref.getDownloadURL();

            // Simpan metadata ke Firestore
            CollectionReference facesRef = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('faces');
            
            await facesRef.add({
              'name': name,
              'imageUrl': imageUrl,
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wajah berhasil didaftarkan.')),
              );
              setState(() {
                _capturedImage = null;
                _nameController.clear();
              });
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal upload ke Firebase: $e')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Gagal mendaftarkan wajah')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error server: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghubungi server. Pastikan Flask berjalan.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambil Foto Wajah'),
      ),
      body: _capturedImage == null ? _buildCameraPreview() : _buildImagePreview(),
    );
  }

  Widget _buildCameraPreview() {
    final theme = Theme.of(context);
    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Menyiapkan Kamera...', style: theme.textTheme.labelMedium),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        // Frame decorations
        Positioned(
          top: 20, left: 20,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.primaryColor, width: 3), left: BorderSide(color: theme.primaryColor, width: 3)))),
        ),
        Positioned(
          top: 20, right: 20,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.primaryColor, width: 3), right: BorderSide(color: theme.primaryColor, width: 3)))),
        ),
        Positioned(
          bottom: 120, left: 20,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.primaryColor, width: 3), left: BorderSide(color: theme.primaryColor, width: 3)))),
        ),
        Positioned(
          bottom: 120, right: 20,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.primaryColor, width: 3), right: BorderSide(color: theme.primaryColor, width: 3)))),
        ),
        // Shutter button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primaryColor, width: 2),
                      color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                    ),
                    child: Icon(
                      Icons.camera,
                      color: theme.primaryColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ambil Foto',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Foto Berhasil Diambil',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.surface),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Lengkap', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _capturedImage = null;
                            _nameController.clear();
                          });
                        },
                        child: const Text('Ambil Ulang'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _registerFace,
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
