import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _communityRepository;

  CommunityBloc({
    required CommunityRepository communityRepository,
  }) : _communityRepository = communityRepository, super(CommunityInitial()) {
    // Workspace Events
    on<CreateWorkspace>(_onCreateWorkspace);
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<LoadWorkspace>(_onLoadWorkspace);
    on<UpdateWorkspace>(_onUpdateWorkspace);
    on<DeleteWorkspace>(_onDeleteWorkspace);

    // Group Events
    on<CreateGroup>(_onCreateGroup);
    on<LoadGroups>(_onLoadGroups);
    on<LoadGroup>(_onLoadGroup);
    on<UpdateGroup>(_onUpdateGroup);
    on<DeleteGroup>(_onDeleteGroup);

    // Message Events
    on<SendMessage>(_onSendMessage);
    on<LoadMessages>(_onLoadMessages);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<DeleteAllMessages>(_onDeleteAllMessages);
    on<AddReaction>(_onAddReaction);
    on<RemoveReaction>(_onRemoveReaction);

    // User Events
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<SetUserOnlineStatus>(_onSetUserOnlineStatus);

    // Admin Events
    on<CheckAdminStatus>(_onCheckAdminStatus);
    on<RemoveUserFromWorkspace>(_onRemoveUserFromWorkspace);
    on<RemoveUserFromGroup>(_onRemoveUserFromGroup);

    // Join/Leave Events
    on<JoinWorkspace>(_onJoinWorkspace);
    on<LeaveWorkspace>(_onLeaveWorkspace);
    on<JoinGroup>(_onJoinGroup);
    on<LeaveGroup>(_onLeaveGroup);

    // Utility Events
    on<ClearError>(_onClearError);
    on<ResetState>(_onResetState);
  }


  // Workspace Handlers
  Future<void> _onCreateWorkspace(
    CreateWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final workspace = await _communityRepository.createWorkspace(
        name: event.name,
        description: event.description,
      );
      emit(WorkspaceCreated(workspace: workspace));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLoadWorkspaces(
    LoadWorkspaces event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final workspaces = await _communityRepository.getUserWorkspaces();
      emit(WorkspacesLoaded(workspaces: workspaces));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLoadWorkspace(
    LoadWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final workspace = await _communityRepository.getWorkspace(event.workspaceId);
      if (workspace != null) {
        emit(WorkspaceLoaded(workspace: workspace));
      } else {
        emit(CommunityError(error: 'Workspace not found'));
      }
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onUpdateWorkspace(
    UpdateWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.updateWorkspace(event.workspace);
      emit(WorkspaceUpdated(workspace: event.workspace));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onDeleteWorkspace(
    DeleteWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.deleteWorkspace(event.workspaceId);
      emit(WorkspaceDeleted(workspaceId: event.workspaceId));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  // Group Handlers
  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final group = await _communityRepository.createGroup(
        workspaceId: event.workspaceId,
        name: event.name,
        description: event.description,
        isPrivate: event.isPrivate,
        memberIds: event.memberIds,
      );
      emit(GroupCreated(group: group));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final groups = await _communityRepository.getWorkspaceGroups(event.workspaceId);
      emit(GroupsLoaded(groups: groups));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLoadGroup(
    LoadGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final group = await _communityRepository.getGroup(event.groupId);
      if (group != null) {
        emit(GroupLoaded(group: group));
      } else {
        emit(CommunityError(error: 'Group not found'));
      }
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onUpdateGroup(
    UpdateGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.updateGroup(event.group);
      emit(GroupUpdated(group: event.group));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onDeleteGroup(
    DeleteGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.deleteGroup(event.groupId);
      emit(GroupDeleted(groupId: event.groupId));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  // Message Handlers
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final message = await _communityRepository.sendMessage(
        groupId: event.groupId,
        content: event.content,
        type: event.type,
        attachmentUrls: event.attachmentUrls,
        replyToMessageId: event.replyToMessageId,
      );
      emit(MessageSent(message: message));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      // This will be handled by stream subscription in the UI
      emit(CommunityLoading());
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.editMessage(event.messageId, event.newContent);
      emit(MessageEdited(
        messageId: event.messageId,
        newContent: event.newContent,
      ));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.deleteMessage(event.messageId, isAdmin: event.isAdmin);
      emit(MessageDeleted(messageId: event.messageId));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onDeleteAllMessages(
    DeleteAllMessages event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.deleteAllMessages(event.groupId);
      emit(AllMessagesDeleted(groupId: event.groupId));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onAddReaction(
    AddReaction event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.addReaction(event.messageId, event.emoji);
      emit(ReactionAdded(
        messageId: event.messageId,
        emoji: event.emoji,
      ));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onRemoveReaction(
    RemoveReaction event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.removeReaction(event.messageId, event.emoji);
      emit(ReactionRemoved(
        messageId: event.messageId,
        emoji: event.emoji,
      ));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  // User Handlers
  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      emit(CommunityLoading());
      final profile = await _communityRepository.getUserProfile(event.uid);
      emit(UserProfileLoaded(profile: profile));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.updateUserProfile(event.profile);
      emit(UserProfileUpdated(profile: event.profile));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onSetUserOnlineStatus(
    SetUserOnlineStatus event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.setUserOnlineStatus(event.isOnline);
      emit(UserOnlineStatusUpdated(isOnline: event.isOnline));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  // Admin Handlers
  Future<void> _onCheckAdminStatus(
    CheckAdminStatus event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final isAdmin = await _communityRepository.isAdmin(event.workspaceId);
      emit(AdminStatusChecked(isAdmin: isAdmin));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onRemoveUserFromWorkspace(
    RemoveUserFromWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.removeUserFromWorkspace(
        event.workspaceId,
        event.userId,
      );
      emit(UserRemovedFromWorkspace(
        workspaceId: event.workspaceId,
        userId: event.userId,
      ));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onRemoveUserFromGroup(
    RemoveUserFromGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.removeUserFromGroup(event.groupId, event.userId);
      emit(UserRemovedFromGroup(
        groupId: event.groupId,
        userId: event.userId,
      ));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  // Utility Handlers
  Future<void> _onClearError(
    ClearError event,
    Emitter<CommunityState> emit,
  ) async {
    // Reset to previous state or initial state
    emit(CommunityInitial());
  }

  Future<void> _onResetState(
    ResetState event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityInitial());
  }

  // Join/Leave Handlers
  Future<void> _onJoinWorkspace(
    JoinWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.joinWorkspace(event.workspaceId);
      emit(CommunitySuccess(message: 'Joined workspace successfully'));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLeaveWorkspace(
    LeaveWorkspace event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.leaveWorkspace(event.workspaceId);
      emit(CommunitySuccess(message: 'Left workspace successfully'));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onJoinGroup(
    JoinGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.joinGroup(event.groupId);
      emit(CommunitySuccess(message: 'Joined group successfully'));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }

  Future<void> _onLeaveGroup(
    LeaveGroup event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.leaveGroup(event.groupId);
      emit(CommunitySuccess(message: 'Left group successfully'));
    } catch (e) {
      emit(CommunityError(error: e.toString()));
    }
  }
}
