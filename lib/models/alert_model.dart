import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String userId;
  final String message;
  final double confidence;
  final String status;
  final String imageUrl;
  final bool read;
  final DateTime? createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.confidence,
    required this.status,
    required this.imageUrl,
    required this.read,
    this.createdAt,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Menangani confidence dengan aman (jika bernilai int atau double di Firestore)
    double confidenceValue = 0.0;
    if (data['confidence'] != null) {
      confidenceValue = (data['confidence'] is int)
          ? (data['confidence'] as int).toDouble()
          : (data['confidence'] as num).toDouble();
    }

    // Menangani createdAt dengan aman untuk menghindari null
    DateTime? createdAtValue;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAtValue = (data['createdAt'] as Timestamp).toDate();
    }

    return AlertModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      confidence: confidenceValue,
      status: data['status'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      read: data['read'] ?? false,
      createdAt: createdAtValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'confidence': confidence,
      'status': status,
      'imageUrl': imageUrl,
      'read': read,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    String? message,
    double? confidence,
    String? status,
    String? imageUrl,
    bool? read,
    DateTime? createdAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AlertModel(id: $id, userId: $userId, message: $message, confidence: $confidence, status: $status, imageUrl: $imageUrl, read: $read, createdAt: $createdAt)';
  }
}
