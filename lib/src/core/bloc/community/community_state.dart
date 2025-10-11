import '../../../data/models/community_models.dart';

abstract class CommunityState {}

// Initial State
class CommunityInitial extends CommunityState {}

// Loading States
class CommunityLoading extends CommunityState {}

// Workspace States
class WorkspacesLoaded extends CommunityState {
  final List<Workspace> workspaces;

  WorkspacesLoaded({required this.workspaces});
}

class WorkspaceLoaded extends CommunityState {
  final Workspace workspace;

  WorkspaceLoaded({required this.workspace});
}

class WorkspaceCreated extends CommunityState {
  final Workspace workspace;

  WorkspaceCreated({required this.workspace});
}

class WorkspaceUpdated extends CommunityState {
  final Workspace workspace;

  WorkspaceUpdated({required this.workspace});
}

// Group States
class GroupsLoaded extends CommunityState {
  final List<Group> groups;

  GroupsLoaded({required this.groups});
}

class GroupLoaded extends CommunityState {
  final Group group;

  GroupLoaded({required this.group});
}

class GroupCreated extends CommunityState {
  final Group group;

  GroupCreated({required this.group});
}

class GroupUpdated extends CommunityState {
  final Group group;

  GroupUpdated({required this.group});
}

class GroupDeleted extends CommunityState {
  final String groupId;

  GroupDeleted({required this.groupId});
}

// Message States
class MessagesLoaded extends CommunityState {
  final List<Message> messages;

  MessagesLoaded({required this.messages});
}

class MessageSent extends CommunityState {
  final Message message;

  MessageSent({required this.message});
}

class MessageEdited extends CommunityState {
  final String messageId;
  final String newContent;

  MessageEdited({
    required this.messageId,
    required this.newContent,
  });
}

class MessageDeleted extends CommunityState {
  final String messageId;

  MessageDeleted({required this.messageId});
}

class AllMessagesDeleted extends CommunityState {
  final String groupId;

  AllMessagesDeleted({required this.groupId});
}

class ReactionAdded extends CommunityState {
  final String messageId;
  final String emoji;

  ReactionAdded({
    required this.messageId,
    required this.emoji,
  });
}

class ReactionRemoved extends CommunityState {
  final String messageId;
  final String emoji;

  ReactionRemoved({
    required this.messageId,
    required this.emoji,
  });
}

// User States
class UserProfileLoaded extends CommunityState {
  final UserProfile profile;

  UserProfileLoaded({required this.profile});
}

class UserProfileUpdated extends CommunityState {
  final UserProfile profile;

  UserProfileUpdated({required this.profile});
}

class UserOnlineStatusUpdated extends CommunityState {
  final bool isOnline;

  UserOnlineStatusUpdated({required this.isOnline});
}

// Admin States
class AdminStatusChecked extends CommunityState {
  final bool isAdmin;

  AdminStatusChecked({required this.isAdmin});
}

class UserRemovedFromWorkspace extends CommunityState {
  final String workspaceId;
  final String userId;

  UserRemovedFromWorkspace({
    required this.workspaceId,
    required this.userId,
  });
}

class UserRemovedFromGroup extends CommunityState {
  final String groupId;
  final String userId;

  UserRemovedFromGroup({
    required this.groupId,
    required this.userId,
  });
}

// Error State
class CommunityError extends CommunityState {
  final String error;

  CommunityError({required this.error});
}

// Success State
class CommunitySuccess extends CommunityState {
  final String message;

  CommunitySuccess({required this.message});
}
