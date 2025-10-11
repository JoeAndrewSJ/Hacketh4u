import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String role;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.isEnabled,
    this.createdAt,
    this.updatedAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] ?? 'user',
      isEnabled: map['isEnabled'] ?? true,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'isEnabled': isEnabled,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? role,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        phoneNumber,
        profileImageUrl,
        role,
        isEnabled,
        createdAt,
        updatedAt,
        fcmToken,
      ];
}
