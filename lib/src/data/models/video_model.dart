import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final String description;
  final String videoUrl; // Firebase Storage URL (backward compatibility)
  final int duration; // in seconds
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Cloudinary streaming fields (optional for backward compatibility)
  final String? cloudinaryPublicId;
  final String? cloudinaryUrl;
  final String? streamingUrl; // HLS streaming URL
  final Map<String, String>? qualities; // Quality-specific URLs (1080p, 720p, 480p)
  final String? thumbnailUrl;
  final bool isCloudinaryProcessed;
  final DateTime? processedAt;
  final String? format;
  final int? width;
  final int? height;

  VideoModel({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.createdAt,
    this.updatedAt,
    this.cloudinaryPublicId,
    this.cloudinaryUrl,
    this.streamingUrl,
    this.qualities,
    this.thumbnailUrl,
    this.isCloudinaryProcessed = false,
    this.processedAt,
    this.format,
    this.width,
    this.height,
  });

  /// Returns true if this video has Cloudinary streaming available
  bool get hasStreamingUrl => streamingUrl != null && streamingUrl!.isNotEmpty;

  /// Returns the best video URL to use (streaming if available, otherwise Firebase)
  String get bestVideoUrl => streamingUrl ?? videoUrl;

  /// Factory constructor from Firestore document
  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel.fromJson(data, doc.id);
  }

  /// Factory constructor from JSON with ID
  factory VideoModel.fromJson(Map<String, dynamic> json, String id) {
    return VideoModel(
      id: id,
      courseId: json['courseId'] ?? '',
      moduleId: json['moduleId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      duration: json['duration'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),

      // Cloudinary fields (optional)
      cloudinaryPublicId: json['cloudinaryPublicId'],
      cloudinaryUrl: json['cloudinaryUrl'],
      streamingUrl: json['streamingUrl'],
      qualities: json['qualities'] != null
          ? Map<String, String>.from(json['qualities'])
          : null,
      thumbnailUrl: json['thumbnailUrl'],
      isCloudinaryProcessed: json['isCloudinaryProcessed'] ?? false,
      processedAt: (json['processedAt'] as Timestamp?)?.toDate(),
      format: json['format'],
      width: json['width'],
      height: json['height'],
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    final json = {
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCloudinaryProcessed': isCloudinaryProcessed,
    };

    // Add optional fields only if they exist
    if (updatedAt != null) json['updatedAt'] = Timestamp.fromDate(updatedAt!);
    if (cloudinaryPublicId != null) json['cloudinaryPublicId'] = cloudinaryPublicId;
    if (cloudinaryUrl != null) json['cloudinaryUrl'] = cloudinaryUrl;
    if (streamingUrl != null) json['streamingUrl'] = streamingUrl;
    if (qualities != null) json['qualities'] = qualities;
    if (thumbnailUrl != null) json['thumbnailUrl'] = thumbnailUrl;
    if (processedAt != null) json['processedAt'] = Timestamp.fromDate(processedAt!);
    if (format != null) json['format'] = format;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;

    return json;
  }

  /// Create a copy with updated fields
  VideoModel copyWith({
    String? id,
    String? courseId,
    String? moduleId,
    String? title,
    String? description,
    String? videoUrl,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cloudinaryPublicId,
    String? cloudinaryUrl,
    String? streamingUrl,
    Map<String, String>? qualities,
    String? thumbnailUrl,
    bool? isCloudinaryProcessed,
    DateTime? processedAt,
    String? format,
    int? width,
    int? height,
  }) {
    return VideoModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      qualities: qualities ?? this.qualities,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isCloudinaryProcessed: isCloudinaryProcessed ?? this.isCloudinaryProcessed,
      processedAt: processedAt ?? this.processedAt,
      format: format ?? this.format,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
