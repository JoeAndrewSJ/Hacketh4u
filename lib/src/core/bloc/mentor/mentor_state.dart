import 'package:equatable/equatable.dart';

class MentorState extends Equatable {
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final List<Map<String, dynamic>> mentors;
  final Map<String, dynamic>? selectedMentor;
  final String searchQuery;

  const MentorState({
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.mentors = const [],
    this.selectedMentor,
    this.searchQuery = '',
  });

  MentorState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? error,
    List<Map<String, dynamic>>? mentors,
    Map<String, dynamic>? selectedMentor,
    String? searchQuery,
  }) {
    return MentorState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      mentors: mentors ?? this.mentors,
      selectedMentor: selectedMentor ?? this.selectedMentor,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isUploading,
        error,
        mentors,
        selectedMentor,
        searchQuery,
      ];
}

// Success States
class MentorsLoaded extends MentorState {
  final List<Map<String, dynamic>> mentors;

  const MentorsLoaded({required this.mentors}) : super(mentors: mentors);

  @override
  List<Object?> get props => [mentors];
}

class MentorCreated extends MentorState {
  final Map<String, dynamic> mentor;

  const MentorCreated({required this.mentor}) : super();

  @override
  List<Object?> get props => [mentor];
}

class MentorUpdated extends MentorState {
  final Map<String, dynamic> mentor;

  const MentorUpdated({required this.mentor}) : super();

  @override
  List<Object?> get props => [mentor];
}

class MentorDeleted extends MentorState {
  final String mentorId;

  const MentorDeleted({required this.mentorId}) : super();

  @override
  List<Object?> get props => [mentorId];
}

class MentorFileUploaded extends MentorState {
  final String fileUrl;

  const MentorFileUploaded({required this.fileUrl}) : super();

  @override
  List<Object?> get props => [fileUrl];
}

// Error States
class MentorError extends MentorState {
  final String error;

  const MentorError({required this.error}) : super(error: error);

  @override
  List<Object?> get props => [error];
}
