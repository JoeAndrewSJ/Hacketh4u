import 'package:flutter_bloc/flutter_bloc.dart';
import 'mentor_event.dart';
import 'mentor_state.dart';
import '../../../data/repositories/mentor_repository.dart';

class MentorBloc extends Bloc<MentorEvent, MentorState> {
  final MentorRepository _mentorRepository;

  MentorBloc({required MentorRepository mentorRepository})
      : _mentorRepository = mentorRepository,
        super(const MentorState()) {
    
    // Mentor CRUD
    on<LoadMentors>(_onLoadMentors);
    on<LoadMentor>(_onLoadMentor);
    on<CreateMentor>(_onCreateMentor);
    on<UpdateMentor>(_onUpdateMentor);
    on<DeleteMentor>(_onDeleteMentor);
    
    // Search
    on<SearchMentors>(_onSearchMentors);
    
    // Upload
    on<UploadMentorProfileImage>(_onUploadMentorProfileImage);
    
    // Reset
    on<ResetMentorState>(_onResetMentorState);
  }

  Future<void> _onLoadMentors(LoadMentors event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final mentors = await _mentorRepository.getAllMentors();
      print('MentorBloc: Loaded ${mentors.length} mentors from Firebase');
      for (var mentor in mentors) {
        print('MentorBloc: ${mentor['name']} - ${mentor['primaryExpertise']}');
      }
      emit(state.copyWith(
        isLoading: false,
        mentors: mentors,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMentor(LoadMentor event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final mentor = await _mentorRepository.getMentorById(event.mentorId);
      emit(state.copyWith(
        isLoading: false,
        selectedMentor: mentor,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateMentor(CreateMentor event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      String? profileImageUrl;
      
      // Upload profile image if provided
      if (event.profileImageFile != null) {
        profileImageUrl = await _mentorRepository.uploadProfileImage(
          event.profileImageFile!,
          'mentor_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      
      // Add image URL to mentor data
      final mentorData = Map<String, dynamic>.from(event.mentorData);
      if (profileImageUrl != null) {
        mentorData['avatarUrl'] = profileImageUrl;
      }
      
      final mentor = await _mentorRepository.createMentor(mentorData);
      print('MentorBloc: Created mentor ${mentor['name']} with ID ${mentor['id']}');
      
      emit(state.copyWith(
        isLoading: false,
        mentors: [...state.mentors, mentor],
      ));
      
      emit(MentorCreated(mentor: mentor));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateMentor(UpdateMentor event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      String? profileImageUrl;
      
      // Upload new profile image if provided
      if (event.profileImageFile != null) {
        profileImageUrl = await _mentorRepository.uploadProfileImage(
          event.profileImageFile!,
          'mentor_${event.mentorId}_${DateTime.now().millisecondsSinceEpoch}',
          existingUrl: event.existingProfileImageUrl,
        );
      }
      
      // Add image URL to mentor data
      final mentorData = Map<String, dynamic>.from(event.mentorData);
      if (profileImageUrl != null) {
        mentorData['avatarUrl'] = profileImageUrl;
      }
      
      final mentor = await _mentorRepository.updateMentor(event.mentorId, mentorData);
      
      // Update mentor in list
      final updatedMentors = state.mentors.map((m) {
        if (m['id'] == event.mentorId) {
          return mentor;
        }
        return m;
      }).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        mentors: updatedMentors,
        selectedMentor: mentor,
      ));
      
      emit(MentorUpdated(mentor: mentor));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteMentor(DeleteMentor event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      await _mentorRepository.deleteMentor(event.mentorId);
      
      // Remove mentor from list
      final updatedMentors = state.mentors.where((m) => m['id'] != event.mentorId).cast<Map<String, dynamic>>().toList();
      
      emit(state.copyWith(
        isLoading: false,
        mentors: updatedMentors,
        selectedMentor: state.selectedMentor?['id'] == event.mentorId ? null : state.selectedMentor,
      ));
      
      emit(MentorDeleted(mentorId: event.mentorId));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSearchMentors(SearchMentors event, Emitter<MentorState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
    
    try {
      final mentors = await _mentorRepository.searchMentors(event.query);
      emit(state.copyWith(mentors: mentors));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUploadMentorProfileImage(UploadMentorProfileImage event, Emitter<MentorState> emit) async {
    emit(state.copyWith(isUploading: true, error: null));
    
    try {
      final url = await _mentorRepository.uploadProfileImage(
        event.filePath,
        'mentor_${event.mentorId}',
      );
      
      emit(state.copyWith(isUploading: false));
      emit(MentorFileUploaded(fileUrl: url));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onResetMentorState(ResetMentorState event, Emitter<MentorState> emit) async {
    emit(const MentorState());
  }
}
