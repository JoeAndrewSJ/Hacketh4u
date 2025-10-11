import 'package:equatable/equatable.dart';

abstract class MentorEvent extends Equatable {
  const MentorEvent();

  @override
  List<Object?> get props => [];
}

// Mentor CRUD Events
class LoadMentors extends MentorEvent {
  const LoadMentors();
}

class LoadMentor extends MentorEvent {
  final String mentorId;

  const LoadMentor(this.mentorId);

  @override
  List<Object?> get props => [mentorId];
}

class CreateMentor extends MentorEvent {
  final Map<String, dynamic> mentorData;
  final String? profileImageFile;

  const CreateMentor({
    required this.mentorData,
    this.profileImageFile,
  });

  @override
  List<Object?> get props => [mentorData, profileImageFile];
}

class UpdateMentor extends MentorEvent {
  final String mentorId;
  final Map<String, dynamic> mentorData;
  final String? profileImageFile;
  final String? existingProfileImageUrl;

  const UpdateMentor({
    required this.mentorId,
    required this.mentorData,
    this.profileImageFile,
    this.existingProfileImageUrl,
  });

  @override
  List<Object?> get props => [mentorId, mentorData, profileImageFile, existingProfileImageUrl];
}

class DeleteMentor extends MentorEvent {
  final String mentorId;

  const DeleteMentor(this.mentorId);

  @override
  List<Object?> get props => [mentorId];
}

// Search Events
class SearchMentors extends MentorEvent {
  final String query;

  const SearchMentors(this.query);

  @override
  List<Object?> get props => [query];
}

// Upload Events
class UploadMentorProfileImage extends MentorEvent {
  final String mentorId;
  final String filePath;

  const UploadMentorProfileImage({
    required this.mentorId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [mentorId, filePath];
}

// Reset Events
class ResetMentorState extends MentorEvent {
  const ResetMentorState();
}
