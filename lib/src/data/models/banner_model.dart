import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String createdBy;
  final String imageUrl;
  final String imagePath; // Storage path for deletion
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.createdBy,
    required this.imageUrl,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BannerModel(
      id: documentId,
      createdBy: map['createdBy'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imagePath: map['imagePath'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  BannerModel copyWith({
    String? id,
    String? createdBy,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
