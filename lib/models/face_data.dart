import 'package:cloud_firestore/cloud_firestore.dart';

class FaceData {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime? createdAt;

  FaceData({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.createdAt,
  });

  factory FaceData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FaceData(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }
}
