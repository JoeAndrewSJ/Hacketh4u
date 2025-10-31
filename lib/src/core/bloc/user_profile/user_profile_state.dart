import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final UserModel user;

  const UserProfileLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class UserProfileUpdated extends UserProfileState {
  final UserModel user;

  const UserProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class UserProfileError extends UserProfileState {
  final String error;

  const UserProfileError({required this.error});

  @override
  List<Object> get props => [error];
}

class ProfileImageUpdating extends UserProfileState {
  final UserModel user;

  const ProfileImageUpdating({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileImageUpdated extends UserProfileState {
  final UserModel user;
  final String newImageUrl;

  const ProfileImageUpdated({
    required this.user,
    required this.newImageUrl,
  });

  @override
  List<Object> get props => [user, newImageUrl];
}
