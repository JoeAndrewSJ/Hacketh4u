import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final double price;
  final String? thumbnailUrl;
  final String category;
  final String level;
  final int duration; // in seconds
  final int moduleCount;
  final bool isPublished;
  final bool isPremium;
  final double rating;
  final int totalReviews;
  final double gstPercentage; // GST percentage (e.g., 18.0 for 18%)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.price,
    this.thumbnailUrl,
    required this.category,
    required this.level,
    required this.duration,
    required this.moduleCount,
    required this.isPublished,
    required this.isPremium,
    required this.rating,
    required this.totalReviews,
    this.gstPercentage = 0.0, // Default 0% GST
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      instructor: map['instructor']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      category: map['category']?.toString() ?? '',
      level: map['level']?.toString() ?? 'beginner',
      duration: map['duration'] as int? ?? 0,
      moduleCount: map['moduleCount'] as int? ?? 0,
      isPublished: map['isPublished'] as bool? ?? false,
      isPremium: map['isPremium'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      gstPercentage: (map['gstPercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'level': level,
      'duration': duration,
      'moduleCount': moduleCount,
      'isPublished': isPublished,
      'isPremium': isPremium,
      'rating': rating,
      'totalReviews': totalReviews,
      'gstPercentage': gstPercentage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        instructor,
        price,
        thumbnailUrl,
        category,
        level,
        duration,
        moduleCount,
        isPublished,
        isPremium,
        rating,
        totalReviews,
        gstPercentage,
        createdAt,
        updatedAt,
      ];

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? instructor,
    double? price,
    String? thumbnailUrl,
    String? category,
    String? level,
    int? duration,
    int? moduleCount,
    bool? isPublished,
    bool? isPremium,
    double? rating,
    int? totalReviews,
    double? gstPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      price: price ?? this.price,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      moduleCount: moduleCount ?? this.moduleCount,
      isPublished: isPublished ?? this.isPublished,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
