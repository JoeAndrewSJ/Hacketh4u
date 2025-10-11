import 'package:equatable/equatable.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserProfileEvent {
  final String uid;

  const LoadUserProfile({required this.uid});

  @override
  List<Object> get props => [uid];
}

class UpdateProfileImage extends UserProfileEvent {
  final String uid;
  final String? oldImageUrl;

  const UpdateProfileImage({
    required this.uid,
    this.oldImageUrl,
  });

  @override
  List<Object?> get props => [uid, oldImageUrl];
}

class UpdateProfileImageUrl extends UserProfileEvent {
  final String uid;
  final String newImageUrl;

  const UpdateProfileImageUrl({
    required this.uid,
    required this.newImageUrl,
  });

  @override
  List<Object> get props => [uid, newImageUrl];
}

class UpdateUserProfile extends UserProfileEvent {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;

  const UpdateUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [uid, name, email, phoneNumber];
}

class ClearUserProfile extends UserProfileEvent {
  const ClearUserProfile();
}
