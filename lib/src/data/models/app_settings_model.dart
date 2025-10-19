import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettings {
  final bool isCommunityEnabled;
  final DateTime? updatedAt;
  final String? updatedBy;

  AppSettings({
    required this.isCommunityEnabled,
    this.updatedAt,
    this.updatedBy,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isCommunityEnabled: json['isCommunityEnabled'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCommunityEnabled': isCommunityEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  AppSettings copyWith({
    bool? isCommunityEnabled,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppSettings(
      isCommunityEnabled: isCommunityEnabled ?? this.isCommunityEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Default settings
  factory AppSettings.defaultSettings() {
    return AppSettings(
      isCommunityEnabled: true,
      updatedAt: DateTime.now(),
    );
  }
}
