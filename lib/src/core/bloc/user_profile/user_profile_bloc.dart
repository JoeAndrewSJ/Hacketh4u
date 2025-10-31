import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserRepository _userRepository;

  UserProfileBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<UpdateProfileImageUrl>(_onUpdateProfileImageUrl);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<ClearUserProfile>(_onClearUserProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileLoading());
    try {
      final user = await _userRepository.getUserProfile(event.uid);
      if (user != null) {
        emit(UserProfileLoaded(user: user));
      } else {
        emit(const UserProfileError(error: 'User profile not found'));
      }
    } catch (e) {
      emit(UserProfileError(error: e.toString()));
    }
  }

  Future<void> _onUpdateProfileImage(
    UpdateProfileImage event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      if (state is UserProfileLoaded) {
        final currentUser = (state as UserProfileLoaded).user;
        emit(ProfileImageUpdating(user: currentUser));

        final newImageUrl = await _userRepository.updateProfileImageWithPicker(
          event.uid,
          event.oldImageUrl,
        );

        final updatedUser = currentUser.copyWith(
          profileImageUrl: newImageUrl,
          updatedAt: DateTime.now(),
        );

        emit(ProfileImageUpdated(
          user: updatedUser,
          newImageUrl: newImageUrl,
        ));
      }
    } catch (e) {
      emit(UserProfileError(error: e.toString()));
    }
  }

  Future<void> _onUpdateProfileImageUrl(
    UpdateProfileImageUrl event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      if (state is UserProfileLoaded) {
        final currentUser = (state as UserProfileLoaded).user;
        
        final updatedUser = currentUser.copyWith(
          profileImageUrl: event.newImageUrl,
          updatedAt: DateTime.now(),
        );

        emit(UserProfileLoaded(user: updatedUser));
      }
    } catch (e) {
      emit(UserProfileError(error: e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      if (state is UserProfileLoaded) {
        final currentUser = (state as UserProfileLoaded).user;
        
        final updatedUser = currentUser.copyWith(
          name: event.name,
          email: event.email,
          phoneNumber: event.phoneNumber,
          updatedAt: DateTime.now(),
        );

        await _userRepository.updateUserProfile(updatedUser);
        await _userRepository.updateDisplayName(event.name);

        emit(UserProfileUpdated(user: updatedUser));
      }
    } catch (e) {
      emit(UserProfileError(error: e.toString()));
    }
  }

  void _onClearUserProfile(
    ClearUserProfile event,
    Emitter<UserProfileState> emit,
  ) {
    emit(UserProfileInitial());
  }
}
